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

#include "input_enum.h"

#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/input.h>
#include <stdlib.h>
#include <dirent.h>
#include <inttypes.h>

#include "utils.h"
#include "erlcmd.h"

static const char response_id = 'r';

struct device_info *device_info_alloc()
{
    struct device_info *info = (struct device_info *) malloc(sizeof(struct device_info));
    memset(info, 0, sizeof(struct device_info));
    return info;
}

void device_info_free(struct device_info *info)
{
    // Free any data
    if (info->fd)
        free(info->fd);
    if (info->name)
        free(info->name);

    // Reset the fields
    memset(info, 0, sizeof(struct device_info));
}

void device_info_free_list(struct device_info *info)
{
    while (info) {
        struct device_info *next = info->next;
        device_info_free(info);
        free(info);
        info = next;
    }
}

/**
 * Filter for the AutoDevProbe scandir on /dev/input.
 *
 * @param dir The current directory entry provided by scandir.
 *
 * @return Non-zero if the given directory entry starts with "event", or zero
 * otherwise.
 */
static int is_event_device(const struct dirent *dir) {
	return strncmp(EVENT_DEV_NAME, dir->d_name, 5) == 0;
}

int enum_devices() {
  if (getuid() != 0)
	  fprintf(stderr, "Not running as root, no devices may be available.\n");

  struct device_info *device_list = find_input_devices();
  int device_list_len = 0;
  for (struct device_info *device = device_list;
         device != NULL;
         device = device->next)
        device_list_len++;
  debug("Found %d devices", device_list_len);
  char resp[4096];
  int resp_index = sizeof(uint16_t); // Space for payload size
  resp[resp_index++] = response_id;
  ei_encode_version(resp, &resp_index);
  ei_encode_list_header(resp, &resp_index, device_list_len);

  for (struct device_info *device = device_list;
         device != NULL;
         device = device->next) {
    ei_encode_tuple_header(resp, &resp_index, 2);
    ei_encode_binary(resp, &resp_index, device->fd, strlen(device->fd));
    ei_encode_binary(resp, &resp_index, device->name,strlen(device->name));
  }
  ei_encode_empty_list(resp, &resp_index);
  erlcmd_send(resp, resp_index);
  device_info_free_list(device_list);
  return 0;
}

struct device_info *find_input_devices() {
  struct dirent **namelist;
	int i, ndev, devnum;
	char *filename;

  struct device_info *info = NULL;

  ndev = scandir(DEV_INPUT_EVENT, &namelist, is_event_device, alphasort);
	if (ndev <= 0)
		return info;

  for (i = 0; i < ndev; i++)
	{

		char fname[64];
		int fd = -1;
		char name[256] = "???";

		snprintf(fname, sizeof(fname),
			 DEV_INPUT_EVENT "/%.32s", namelist[i]->d_name);
		fd = open(fname, O_RDONLY);
		if (fd < 0)
			continue;

		ioctl(fd, EVIOCGNAME(sizeof(name)), name);
    close(fd);

    struct device_info *new_info = device_info_alloc();

    new_info->fd = strdup(fname);
    new_info->name = strdup(name);

    new_info->next = info;
    info = new_info;

		free(namelist[i]);
	}
  free(namelist);
  return info;
}
