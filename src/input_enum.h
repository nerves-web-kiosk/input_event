/*
 *  Copyright 2016 Justin Schneck
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef INPUT_ENUM_H
#define INPUT_ENUM_H

#define DEV_INPUT_EVENT "/dev/input"
#define EVENT_DEV_NAME "event"

struct device_info {
    char *fd;
    char *name;

    struct device_info *next;
};

struct device_info *device_info_alloc(void);
void device_info_free(struct device_info *info);
void device_info_free_list(struct device_info *info);

int enum_devices(void);
struct device_info *find_input_devices(void);

#endif
