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
#include <stdio.h>
#include <stdint.h>
#include <err.h>

#include <linux/version.h>
#include <linux/input.h>

#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <errno.h>


#include <sys/types.h>
#include <sys/stat.h>
#include <poll.h>

#include "utils.h"
#include "input_enum.h"
#include "erlcmd.h"

static const char notification_id = 'n';
static const char error_id = 'e';

void device_handle_request(const char *req, void *cookie) {
  debug("Erl sent data");
}

void device_process(int fd) {
  struct input_event ev[64];
  int i, rd;
  debug("Read");
  rd = read(fd, ev, sizeof(struct input_event) * 64);
  if (rd < (int) sizeof(struct input_event)) {
		warn("error from read - expected %d bytes, got %d", (int) sizeof(struct input_event), rd);
		return;
	}

  for (i = 0; i < rd / sizeof(struct input_event); i++) {

    char resp[sizeof(struct input_event) * 64];
    int resp_index = sizeof(uint16_t); // Space for payload size

    debug("New event");
    debug("Type: %d", ev[i].type);
    debug("Code: %d", ev[i].code);
    debug("Value: %d", ev[i].value);

    resp[resp_index++] = notification_id;
    ei_encode_version(resp, &resp_index);
    ei_encode_tuple_header(resp, &resp_index, 4);
    ei_encode_atom(resp, &resp_index, "event");

    ei_encode_long(resp, &resp_index, ev[i].type);
    ei_encode_long(resp, &resp_index, ev[i].code);
    ei_encode_long(resp, &resp_index, ev[i].value);
    erlcmd_send(resp, resp_index);
  }
}

void device_closed(int fd) {
  char resp[sizeof(struct input_event) * 64];
  int resp_index = sizeof(uint16_t); // Space for payload size

  resp[resp_index++] = error_id;

  ei_encode_version(resp, &resp_index);
  ei_encode_tuple_header(resp, &resp_index, 2);
  ei_encode_atom(resp, &resp_index, "error");
  ei_encode_atom(resp, &resp_index, "closed");
  erlcmd_send(resp, resp_index);
}

static int open_device(const char *dev) {
  int version, fd;

  fd = open(dev, O_RDONLY);
  if (errno == EACCES && getuid() != 0)
    err(EXIT_FAILURE, "You do not have access to %s.", dev);

  if (ioctl(fd, EVIOCGVERSION, &version))
		err(EXIT_FAILURE, "can't get version");

  debug("Input driver version is %d.%d.%d\n",
		version >> 16, (version >> 8) & 0xff, version & 0xff);

  struct erlcmd handler;
  erlcmd_init(&handler, device_handle_request, &fd);

  for (;;) {
    struct pollfd fdset[2];

    fdset[0].fd = STDIN_FILENO;
    fdset[0].events = POLLIN;
    fdset[0].revents = 0;

    fdset[1].fd = fd;
    fdset[1].events = (POLLIN | POLLPRI | POLLHUP);
    fdset[1].revents = 0;

    int timeout = -1; // Wait forever unless told by otherwise
    int rc = poll(fdset, 2, timeout);

    if (fdset[0].revents & (POLLIN | POLLHUP))
      erlcmd_process(&handler);

    if (fdset[1].revents & POLLIN)
      device_process(fd);

    if (fdset[1].revents & POLLHUP) {
      device_closed(fd);
      break;
    }
  }
  debug("Exit");
  return 0;
}

int main(int argc, char *argv[]) {
  if (argc != 2)
    errx(EXIT_FAILURE, "Expecting path or 'enumerate'");

  if (strcmp(argv[1], "enumerate") == 0)
    return enum_devices();
  else
    return open_device(argv[1]);
}
