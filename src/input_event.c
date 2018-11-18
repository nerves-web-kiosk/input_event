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

#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/uio.h>
#include <linux/input.h>

#ifdef DEBUG
FILE *log_location;
#define LOG_LOCATION log_location
#define debug(...) do { fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\r\n"); fflush(stderr); } while(0)
#else
#define LOG_LOCATION stderr
#define debug(...)
#endif

#define INPUT_EVENT_REPORT 1
#define INPUT_EVENT_VERSION 2
#define INPUT_EVENT_NAME 3
#define INPUT_EVENT_ID 4
#define INPUT_EVENT_REPORT_INFO 5
#define INPUT_EVENT_READY 6

#define MAX_EVENTS_PER_READ 64
static struct input_event input_buffer[MAX_EVENTS_PER_READ];
static uint8_t report_buffer[MAX_EVENTS_PER_READ * 8 + 4];

static void send_report(void *buffer, size_t buffer_len, uint8_t report, uint8_t sub)
{
    uint8_t header[4];
    size_t len = buffer_len + sizeof(header) - 2;
    header[0] = (uint8_t) (len >> 8);
    header[1] = (len & 0xff);
    header[2] = report;
    header[3] = sub;

    struct iovec iov[2];
    iov[0].iov_base = header;
    iov[0].iov_len = sizeof(header);
    iov[1].iov_base = buffer;
    iov[1].iov_len = buffer_len;

    if (writev(STDOUT_FILENO, iov, 2) < 0)
        err(EXIT_FAILURE, "writev failed");
}

static void process_events(int fd)
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

    size_t event_count = rd / sizeof(struct input_event);

    uint8_t *p = report_buffer;
    for (size_t i = 0; i < event_count; i++) {
        memcpy(p, &input_buffer[i].type, 8);
        p += 8;
    }

    send_report(report_buffer, p - report_buffer, INPUT_EVENT_REPORT, 0);
}

#define BITS_PER_LONG (sizeof(long) * 8)
#define NBITS(x) ((((x)-1)/BITS_PER_LONG)+1)
#define OFF(x)  ((x)%BITS_PER_LONG)
#define BIT(x)  (1UL<<OFF(x))
#define LONG(x) ((x)/BITS_PER_LONG)
#define test_bit(bit, array)	((array[LONG(bit)] >> OFF(bit)) & 1)

static void send_version(int fd)
{
    int version;
    if (ioctl(fd, EVIOCGVERSION, &version) < 0)
        err(EXIT_FAILURE, "EVIOCGVERSION");

    char version_str[16];
    int len = sprintf(version_str, "%d.%d.%d", version >> 16, (version >> 8) & 0xff, version & 0xff);
    send_report(version_str, len, INPUT_EVENT_VERSION, 0);
}

static void send_name(int fd)
{
    char name[256];
    if (ioctl(fd, EVIOCGNAME(sizeof(name)), name) < 0)
        err(EXIT_FAILURE, "EVIOCGNAME");

    send_report(name, strlen(name), INPUT_EVENT_NAME, 0);
}

static void send_id(int fd)
{
    unsigned short id[4];

    // id[0] -> bus
    // id[1] -> vendor
    // id[2] -> product
    // id[3] -> version

    if (ioctl(fd, EVIOCGID, id) < 0)
        err(EXIT_FAILURE, "EVIOCGID");
    send_report(id, sizeof(id), INPUT_EVENT_ID, 0);
}

static uint8_t *append_uint16(uint8_t *p, uint16_t value)
{
    memcpy(p, &value, sizeof(uint16_t));
    return p + sizeof(uint16_t);
}

static uint8_t *append_int32(uint8_t *p, int32_t value)
{
    memcpy(p, &value, sizeof(int32_t));
    return p + sizeof(int32_t);
}

static void send_report_info(int fd)
{
    // Send up information about the reports. Each report info has a "sub"
    // field that indicates the report type. The codes are then listed (16-bits/code).
    // If the report type is EV_ABS, then each code is followed by 5 32-bit values.

    unsigned long bit[EV_MAX][NBITS(KEY_MAX)];
    memset(bit, 0, sizeof(bit));
    if (ioctl(fd, EVIOCGBIT(0, EV_MAX), bit[0]) < 0)
        err(EXIT_FAILURE, "EVIOCGBIT");

    for (uint16_t i = 1; i < EV_MAX; i++) {
        if (test_bit(i, bit[0]) && i != EV_REP) {
            if (ioctl(fd, EVIOCGBIT(i, KEY_MAX), bit[i]) < 0)
                continue;

            uint8_t *p = report_buffer;
            for (uint16_t j = 0; j < KEY_MAX; j++) {
                if (test_bit(j, bit[i])) {
                    p = append_uint16(p, j);
                    if (i == EV_ABS) {
                        int abs[6];
                        if (ioctl(fd, EVIOCGABS(j), abs) < 0)
                            err(EXIT_FAILURE, "EVIOCGABS(%d)", j);
                        for (int k = 0; k < 6; k++)
                            p = append_int32(p, abs[k]);
                    }
                }
            }
            send_report(report_buffer, p - report_buffer, INPUT_EVENT_REPORT_INFO, i);
        }
    }

    if (test_bit(EV_REP, bit[0])) {
        unsigned int rep[REP_MAX + 1];
        if (ioctl(fd, EVIOCGREP, rep) < 0)
            err(EXIT_FAILURE, "EVIOCGREP");

        uint8_t *p = report_buffer;
        for (uint16_t i = 0; i <= REP_MAX; i++)
            p = append_int32(p, rep[i]);

        send_report(report_buffer, p - report_buffer, INPUT_EVENT_REPORT_INFO, EV_REP);
    }
}

int main(int argc, char *argv[])
{
    if (argc != 2)
        errx(EXIT_FAILURE, "Pass the device to monitor");

    const char *input_path = argv[1];
    int fd = open(input_path, O_RDONLY);
    if (errno == EACCES && getuid() != 0)
        err(EXIT_FAILURE, "You do not have access to %s.", input_path);

    send_version(fd);
    send_name(fd);
    send_id(fd);
    send_report_info(fd);

    send_report(NULL, 0, INPUT_EVENT_READY, 0);

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
            process_events(fd);

        // Check for Elixir going away
        if (fdset[0].revents & (POLLIN | POLLHUP))
            exit(EXIT_SUCCESS);
    }
}
