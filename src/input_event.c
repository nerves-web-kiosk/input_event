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

#include <sys/inotify.h>
#include <sys/uio.h>

#include <poll.h>

#include "utils.h"
#include "input_enum.h"

#define INPUT_EVENT_EVENT 1
#define INPUT_EVENT_CLOSED 2
#define INPUT_EVENT_REENUMERATE 3
#define INPUT_EVENT_INOTIFY 4

#define MAX_EVENTS_PER_READ 64
static struct input_event input_buffer[MAX_EVENTS_PER_READ];
static char report_buffer[MAX_EVENTS_PER_READ * 8 + 4];

static void device_process(int fd)
{
    // Read as many the input events as possible
    ssize_t rd = read(fd, input_buffer, sizeof(input_buffer));
    if (rd < 0)
        err(EXIT_FAILURE, "read failed");
    if (rd % sizeof(struct input_event))
        errx(EXIT_FAILURE, "read returned %d which is not a multiple of %d!", (int) rd, (int) sizeof(struct input_event));

    // Package them for processing in Elixir.
    // The event timestamps have platform-dependent sizes (it's a timeval), so
    // strip them off. The rest of the event struct is well-defined.

    int event_count = rd / sizeof(struct input_event);
    int report_len = event_count * 8 + 2; // Don't count the size field in the header

    // Fill out the header
    report_buffer[0] = (report_len >> 8);
    report_buffer[1] = (report_len & 0xff);
    report_buffer[2] = INPUT_EVENT_EVENT;
    report_buffer[3] = 0;

    char *p = &report_buffer[4];
    for (int i = 0; i < event_count; i++) {
        memcpy(p, &input_buffer[i].type, 8);
        p += 8;
    }

    if (write(STDOUT_FILENO, report_buffer, report_len + 2) < 0)
        err(EXIT_FAILURE, "writev failed");
}

int main(int argc, char *argv[])
{
    if (argc != 2)
        errx(EXIT_FAILURE, "Pass the device to monitor");

    const char *input_path = argv[1];
    int fd = open(input_path, O_RDONLY);
    if (errno == EACCES && getuid() != 0)
        err(EXIT_FAILURE, "You do not have access to %s.", input_path);

    int version;
    if (ioctl(fd, EVIOCGVERSION, &version))
        err(EXIT_FAILURE, "can't get version");

    debug("Input driver version is %d.%d.%d\n",
          version >> 16, (version >> 8) & 0xff, version & 0xff);

    for (;;) {
        struct pollfd fdset[2];

        fdset[0].fd = STDIN_FILENO;
        fdset[0].events = POLLIN;
        fdset[0].revents = 0;

        fdset[1].fd = fd;
        fdset[1].events = (POLLIN | POLLPRI | POLLHUP);
        fdset[1].revents = 0;

        int rc = poll(fdset, 2, -1);
        if (rc < 0)
            err(EXIT_FAILURE, "poll");

        if (fdset[1].revents & (POLLIN | POLLHUP))
            device_process(fd);

        // Check for Elixir going away
        if (fdset[0].revents & (POLLIN | POLLHUP)) {
            warnx("Got input from Elixir? 0x%08x", fdset[0].revents);
            break;
        }
    }
}
