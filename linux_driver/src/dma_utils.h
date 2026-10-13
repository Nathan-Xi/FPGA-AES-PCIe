
#ifndef _DMA_UTILS_H_
#define _DMA_UTILS_H_

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <sys/types.h>

#define RW_MAX_SIZE     0x7ffff000

uint64_t getopt_integer(char *optarg);
ssize_t read_to_buffer(char *fname, int fd, char *buffer, uint64_t size, uint64_t base);
ssize_t write_from_buffer(char *fname, int fd, char *buffer, uint64_t size, uint64_t base);
static int timespec_check(struct timespec *t);
void timespec_sub(struct timespec *t1, struct timespec *t2);

#endif /* _DMA_UTILS_H_ */
