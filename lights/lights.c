/*
 * Copyright (C) 2019 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//#include <cutils/properties.h>
#include <log/log.h>

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>

#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <sys/types.h>

#include <hardware/lights.h>

static pthread_once_t g_init = PTHREAD_ONCE_INIT;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;

char const*const RED_LED_FILE =
        "/sys/class/leds/sei610:red:power/brightness";

char const*const BLUE_LED_FILE =
        "/sys/class/leds/sei610:blue:bt/brightness";

#define LA_P0_ENABLE	0x12
#define LA_P1_ENABLE	0x13
#define LA_RED0_ADDR	0x20
#define LA_GREEN0_ADDR	0x21
#define LA_BLUE0_ADDR	0x22
#define LA_RED1_ADDR	0x23
#define LA_GREEN1_ADDR	0x24
#define LA_BLUE1_ADDR	0x25
#define LA_RED2_ADDR	0x26
#define LA_GREEN2_ADDR	0x27
#define LA_BLUE2_ADDR	0x28
#define LA_RED3_ADDR	0x29
#define LA_GREEN3_ADDR	0x2A
#define LA_BLUE3_ADDR	0x2B
#define LA_RESET_ADDR	0x7F
char const*const ARRAY_LED_DEVICE = "/dev/i2c-0";
const int i2c_dev_addr = (0xB6 >> 1); /* 0x5B */

struct yukawa_light_device_t {
    struct light_device_t hw_device;
    struct light_state_t state;
    int fd;
    pthread_mutex_t la_lock;
    pthread_cond_t la_cv;
    pthread_t la_thread;
    int la_end;
};

/**
 * device methods
 */

void init_globals(void)
{
    pthread_mutex_init(&g_lock, NULL);
}

static int sys_write_int(int fd, int value)
{
    char buffer[16];
    size_t bytes;
    ssize_t amount;

    bytes = snprintf(buffer, sizeof(buffer), "%d\n", value);
    if (bytes >= sizeof(buffer))
        return -EINVAL;
    amount = write(fd, buffer, bytes);
    return amount == -1 ? -errno : 0;
}

static int rgb_to_brightness(struct light_state_t const* state)
{
    int color = state->color & 0x00ffffff;
    return ((77*((color>>16)&0x00ff)) +
            (150*((color>>8)&0x00ff)) + (29*(color&0x00ff))) >> 8;
}

static int set_light_bluetooth(struct light_device_t* dev,
        struct light_state_t const* state)
{
    struct yukawa_light_device_t* ldev = (struct yukawa_light_device_t*)dev;
    int blue = rgb_to_brightness(state);

    pthread_mutex_lock(&g_lock);
    if (ldev->fd <= 0) {
        ldev->fd = open(BLUE_LED_FILE, O_WRONLY);
        if (ldev->fd < 0) {
            pthread_mutex_unlock(&g_lock);
            return -errno;
        }
    }
    ldev->state = *state;
    sys_write_int(ldev->fd, blue);
    pthread_mutex_unlock(&g_lock);
    return 0;
}

static int set_light_battery(struct light_device_t* dev,
        struct light_state_t const* state)
{
    struct yukawa_light_device_t* ldev = (struct yukawa_light_device_t*)dev;
    int red = rgb_to_brightness(state);

    pthread_mutex_lock(&g_lock);
    if (ldev->fd <= 0) {
        ldev->fd = open(RED_LED_FILE, O_WRONLY);
        if (ldev->fd < 0) {
            pthread_mutex_unlock(&g_lock);
            return -errno;
        }
    }
    ldev->state = *state;
    sys_write_int(ldev->fd, red);
    pthread_mutex_unlock(&g_lock);
    return 0;
}

static int write8reg8(int fd, uint8_t regaddr, uint8_t cmd)
{
    uint8_t buf[2];

    buf[0] = regaddr;
    buf[1] = cmd;
    if (write(fd, buf, 2) != 2)
        return -1;
    return 0;
}

void *led_array_thread_loop(void *context)
{
    struct yukawa_light_device_t* ldev = (struct yukawa_light_device_t*)context;
    useconds_t la_sleep;
    unsigned int i = 0;

    while (1) {
        pthread_mutex_lock(&ldev->la_lock);
        write8reg8(ldev->fd, LA_P0_ENABLE, 0xFF);
        write8reg8(ldev->fd, LA_P1_ENABLE, 0xFF);
        if (ldev->la_end == 1) {
            ALOGE("%s: Exit", __func__);
            break;
        }
        if (ldev->state.flashMode == LIGHT_FLASH_TIMED) {
            switch (i & 0x3) {
            case 3: /* LED4: P0_5, P0_6, P0_7 */
                write8reg8(ldev->fd, LA_P0_ENABLE, 0x1F);
                break;
            case 2: /* LED3: P0_2, P0_3, P0_4 */
                write8reg8(ldev->fd, LA_P0_ENABLE, 0xE3);
                break;
            case 1: /* LED2: P1_3, P0_0, P0_1 */
                write8reg8(ldev->fd, LA_P0_ENABLE, 0xFC);
                write8reg8(ldev->fd, LA_P1_ENABLE, 0xF7);
                break;
            case 0: /* LED1: P1_0, P1_1, P1_2 */
                write8reg8(ldev->fd, LA_P1_ENABLE, 0xF8);
                break;
            }
            i = (i == 3) ? 0 : i + 1;
            la_sleep = ldev->state.flashOnMS * 1000;
        } else {
            if (ldev->state.color != 0) {
                write8reg8(ldev->fd, LA_P0_ENABLE, 0x00);
                write8reg8(ldev->fd, LA_P1_ENABLE, 0x00);
            }
            pthread_cond_wait(&ldev->la_cv, &ldev->la_lock);
            la_sleep = 0;
        }
        pthread_mutex_unlock(&ldev->la_lock);
        usleep(la_sleep);
    }
    pthread_mutex_unlock(&ldev->la_lock);
    return NULL;
}

static int set_array_light_unlocked(struct light_device_t* dev,
        struct light_state_t const* state)
{ /* Color format is ARGB */
    struct yukawa_light_device_t* ldev = (struct yukawa_light_device_t*)dev;
    int red, green, blue, fmode;

    ALOGD("%s mode %d, colorRGB=%08X, onMS=%d, offMS=%d\n",
          __func__, state->flashMode, state->color, state->flashOnMS,
          state->flashOffMS);

    if (ldev->fd <= 0)
        return -1;

    pthread_mutex_lock(&ldev->la_lock);

    fmode = ldev->state.flashMode;
    ldev->state = *state;

    red = (state->color >> 16) & 0xFF;
    green = (state->color >> 8) & 0xFF;
    blue = state->color & 0xFF;

    write8reg8(ldev->fd, LA_RED0_ADDR, red);
    write8reg8(ldev->fd, LA_GREEN0_ADDR, green);
    write8reg8(ldev->fd, LA_BLUE0_ADDR, blue);

    write8reg8(ldev->fd, LA_RED1_ADDR, red);
    write8reg8(ldev->fd, LA_GREEN1_ADDR, green);
    write8reg8(ldev->fd, LA_BLUE1_ADDR, blue);

    write8reg8(ldev->fd, LA_RED2_ADDR, red);
    write8reg8(ldev->fd, LA_GREEN2_ADDR, green);
    write8reg8(ldev->fd, LA_BLUE2_ADDR, blue);

    write8reg8(ldev->fd, LA_RED3_ADDR, red);
    write8reg8(ldev->fd, LA_GREEN3_ADDR, green);
    write8reg8(ldev->fd, LA_BLUE3_ADDR, blue);

    if (fmode != LIGHT_FLASH_TIMED) {
        if (state->color == 0) {
            write8reg8(ldev->fd, LA_P0_ENABLE, 0xFF);
            write8reg8(ldev->fd, LA_P1_ENABLE, 0xFF);
        } else {
            write8reg8(ldev->fd, LA_P0_ENABLE, 0x00);
            write8reg8(ldev->fd, LA_P1_ENABLE, 0x00);
        }
    }

    if (fmode != state->flashMode)
        pthread_cond_signal(&ldev->la_cv);
    pthread_mutex_unlock(&ldev->la_lock);

    return 0;
}

static int set_light_notifications(struct light_device_t* dev,
        struct light_state_t const* state)
{
    struct yukawa_light_device_t* ldev = (struct yukawa_light_device_t*)dev;
    int ret;

    pthread_mutex_lock(&g_lock);
    if (ldev->fd <= 0) {
        ldev->fd = open(ARRAY_LED_DEVICE, O_RDWR);
        if (ldev->fd < 0) {
            pthread_mutex_unlock(&g_lock);
            return -errno;
        }
        if (ioctl(ldev->fd, I2C_SLAVE, i2c_dev_addr) < 0) {
            ALOGE("%s: Error setting slave addr\n", __func__);
            close(ldev->fd);
            ldev->fd = 0;
            pthread_mutex_unlock(&g_lock);
            return -errno;
        }
        write8reg8(ldev->fd, LA_RESET_ADDR, 0x00);
    }

    if (ldev->la_thread == 0) {
        pthread_cond_init(&ldev->la_cv, NULL);
        pthread_mutex_init(&ldev->la_lock, NULL);
        pthread_create(&ldev->la_thread, (const pthread_attr_t *)NULL,
                led_array_thread_loop, dev);
    }

    ret = set_array_light_unlocked(dev, state);
    pthread_mutex_unlock(&g_lock);
    return ret;
}

static int set_light_attention(struct light_device_t* dev,
        struct light_state_t const* state)
{
    set_light_notifications(dev, state);
    return 0;
}

/** Close the lights device */
static int close_lights(struct light_device_t* dev)
{
    struct yukawa_light_device_t* ldev = (struct yukawa_light_device_t*)dev;

    if (ldev) {
        if (ldev->la_thread > 0) {
            pthread_mutex_lock(&ldev->la_lock);
            ldev->la_end = 1;
            pthread_cond_signal(&ldev->la_cv);
            pthread_mutex_unlock(&ldev->la_lock);
            pthread_join(ldev->la_thread, NULL);
        }
        if (ldev->fd > 0)
            close(ldev->fd);
        free(ldev);
    }
    return 0;
}

/*
 * module methods
 */

/* Open a new instance of a lights device using name */
static int open_lights(const struct hw_module_t* module, char const* name,
        struct hw_device_t** device)
{
    int (*set_light)(struct light_device_t* dev,
            struct light_state_t const* state);
    struct yukawa_light_device_t *ldev;

    if (strcmp(LIGHT_ID_BATTERY, name) == 0)
        set_light = set_light_battery;
    else if (strcmp(LIGHT_ID_BLUETOOTH, name) == 0)
        set_light = set_light_bluetooth;
    else if (0 == strcmp(LIGHT_ID_NOTIFICATIONS, name))
        set_light = set_light_notifications;
    else if (0 == strcmp(LIGHT_ID_ATTENTION, name))
        set_light = set_light_attention;
    else
        return -EINVAL;

    pthread_once(&g_init, init_globals);

    ldev = calloc(1, sizeof(struct yukawa_light_device_t));

    if (!ldev)
        return -ENOMEM;

    ldev->hw_device.common.tag = HARDWARE_DEVICE_TAG;
    ldev->hw_device.common.version = LIGHTS_DEVICE_API_VERSION_2_0;
    ldev->hw_device.common.module = (struct hw_module_t*)module;
    ldev->hw_device.common.close = (int (*)(struct hw_device_t*))close_lights;
    ldev->hw_device.set_light = set_light;

    *device = (struct hw_device_t*)ldev;
    return 0;
}

static struct hw_module_methods_t lights_module_methods = {
    .open =  open_lights,
};

/*
 * The lights Module
 */
struct hw_module_t HAL_MODULE_INFO_SYM = {
    .tag = HARDWARE_MODULE_TAG,
    .version_major = 1,
    .version_minor = 0,
    .id = LIGHTS_HARDWARE_MODULE_ID,
    .name = "Lights Module",
    .author = "Google, Inc.",
    .methods = &lights_module_methods,
};
