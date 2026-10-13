#include <fcntl.h>
#include <getopt.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/ioctl.h>

#include "dma_utils.h"

static struct option const long_opts[] = {
	{"size", required_argument, NULL, 's'},
	{"cycle", required_argument, NULL, 'c'},
};

#define DEVICE_NAME_H2C "/dev/bdma0_h2c_0"
#define DEVICE_NAME_C2H "/dev/bdma0_c2h_0"
#define ADDR_DEFAULT (0)

static int dma_h2c(char *devname, int fpga_fd, uint64_t addr, uint64_t size, char *buffer_write);
static int dma_c2h(char *devname, int fpga_fd, uint64_t addr, uint64_t size, char *buffer_read);

int main(int argc, char *argv[]) {

	char *buffer_write = NULL;
	char *buffer_read = NULL;
	int cmd_opt = 0;
	uint64_t cycle = 0;
	uint64_t address = ADDR_DEFAULT;
	uint64_t size;
	char *allocated_write = NULL;
	char *allocated_read = NULL;
	uint64_t count_diff = 0;
	long read_time, write_time;
	long read_avg_time = 0;
	long read_min_time = 0;
	long read_max_time = 0;
	long write_avg_time = 0;
	long write_min_time = 0;
	long write_max_time = 0;
	long write_total_time = 0;
	long read_total_time = 0;
	struct timespec ts_start, ts_end;

	if (argc < 5) {
        	printf("Usage: %s -c <cycle> -s <size>\n", argv[0]);
        	return 1;
    	}

	while ((cmd_opt = getopt_long(argc, argv, "c:a:s:h:", long_opts, NULL)) != -1) {

		switch (cmd_opt) {
			case 'c':
				cycle = getopt_integer(optarg);
				break;
			case 's':
				size = getopt_integer(optarg);
				break;
			case 'h':
                                printf("Usage: %s -c <cycle> -s <size>\n", argv[0]);
				exit(0);
			default:
				exit(0);
				break;
		}
	}

	/* allocate memory */
	posix_memalign((void **)&allocated_write, 4096 /*alignment */ , size + 4096);

	if (!allocated_write) {

        	fprintf(stderr, "OOM %lu.\n", size + 4096);
        }

        buffer_write = allocated_write;

	posix_memalign((void **)&allocated_read, 4096 /*alignment */ , size + 4096);

	if (!allocated_read) {

        	fprintf(stderr, "OOM %lu.\n", size + 4096);
        }

        buffer_read = allocated_read;

	/* open bdma */
	int fpga_write_fd = open(DEVICE_NAME_H2C, O_RDWR);
        if (fpga_write_fd < 0) {

                fprintf(stderr, "unable to open device %s, %d.\n",
                        DEVICE_NAME_H2C, fpga_write_fd);
                perror("open device");
                return -EINVAL;
        }

        int fpga_read_fd = open(DEVICE_NAME_C2H, O_RDWR | O_TRUNC);

        if (fpga_read_fd < 0) {

                fprintf(stderr, "unable to open device %s, %d.\n",
                        DEVICE_NAME_C2H, fpga_read_fd);
                perror("open device");
                return -EINVAL;
        }

        /* assigning value to buffer */
        srand(time(NULL));
        for(int i = 0; i < size; i++) {
                buffer_write[i] = rand() % 256;
                buffer_read[i] = 0;
        }

	/* cycle write and read */
	for(int i = 0; i < cycle; i++) {
		/* write */
		clock_gettime(CLOCK_MONOTONIC, &ts_start);
		dma_h2c(DEVICE_NAME_H2C, fpga_write_fd, address, size, buffer_write);
		clock_gettime(CLOCK_MONOTONIC, &ts_end);	
		timespec_sub(&ts_end, &ts_start);
		write_time = ts_end.tv_nsec;

        	/* get write max time, min time and avg time */	
		if(i == 0) {
                	write_min_time = ts_end.tv_nsec;
                	write_max_time = ts_end.tv_nsec;
        	}
	
		write_total_time += ts_end.tv_nsec;
        	if (ts_end.tv_nsec > write_max_time)
			write_max_time = ts_end.tv_nsec;
		if (ts_end.tv_nsec < write_min_time)
			write_min_time = ts_end.tv_nsec;
		
		/* read */
		clock_gettime(CLOCK_MONOTONIC, &ts_start);
        	dma_c2h(DEVICE_NAME_C2H, fpga_read_fd, address, size, buffer_read);
	        clock_gettime(CLOCK_MONOTONIC, &ts_end);        
	        timespec_sub(&ts_end, &ts_start);
		read_time = ts_end.tv_nsec;

		/* get read max time, min time and avg time */
        	if(i == 0) {
                	read_min_time = ts_end.tv_nsec;
                	read_max_time = ts_end.tv_nsec;
        	}

        	read_total_time += ts_end.tv_nsec;
        	if (ts_end.tv_nsec > read_max_time)
                	read_max_time = ts_end.tv_nsec;
        	if (ts_end.tv_nsec < read_min_time)
                	read_min_time = ts_end.tv_nsec;

		/* compare read buffer and write buffer */
		for(int j = 0; j < size; j++) {
			if(buffer_read[j] != buffer_write[j])
				count_diff++;
		}

 		/* print */	
	        if(count_diff > 0) {
                	printf("count_diff num is %d, Bit error rate is %f\n", count_diff, (float)(count_diff/size));
			goto out;
	       	} else {
			printf("size: %lu KByte, write speed: %d MB/s, read speed: %d MB/s, error: %0.1f\%\n", size/1024, size*1000/write_time, size*1000/read_time, (float)(count_diff/size));
		}
	}
	

	/* printing read and write maximum minimum and average rates */
	write_avg_time = write_total_time/cycle;

	printf("\nwrite\n");
	printf("    max: %d MB/s, min: %d MB/s, avg: %d MB/s\n", \
		       	size*1000/write_min_time, size*1000/write_max_time, size*1000/write_avg_time);

	read_avg_time = read_total_time/cycle;

	printf("read\n");	
	printf("    max: %d MB/s, min: %d MB/s, avg: %d MB/s\n", \
			size*1000/read_min_time, size*1000/read_max_time, size*1000/read_avg_time);

out:
	free(buffer_write);
	free(buffer_read);
	close(fpga_write_fd);
	close(fpga_read_fd);	

        return 0;

}

static int dma_h2c(char *devname, int fpga_fd, uint64_t addr,uint64_t size, char *buffer_write) {
	uint64_t i;
	ssize_t rc;
	size_t bytes_done = 0;
	char *buffer = buffer_write;
	int underflow = 0;
	
	/* write buffer to AXI MM address using SGDMA */
	rc = write_from_buffer(devname, fpga_fd, buffer, size, addr);
	
	if (rc < 0)
		goto out;

	bytes_done = rc;

	if (bytes_done < size) {

		printf("%ld: underflow %ld/%ld.\n", i, bytes_done, size);
		underflow = 1;
	}

out:
	if (rc < 0)
		return rc;
	/* treat underflow as error */
	return underflow ? -EIO : 0;
}



static int dma_c2h(char *devname, int fpga_fd, uint64_t addr, uint64_t size, char *buffer_read) {
	ssize_t rc = 0;
	size_t bytes_done = 0;
	uint64_t i;
	char *buffer = NULL;

	int underflow = 0;

	rc = read_to_buffer(devname, fpga_fd, buffer_read, size, addr);
	if (rc < 0)
		goto out;
	bytes_done = rc;

	if (bytes_done < size) {
		fprintf(stderr, "#%ld: underflow %ld/%ld.\n",
			i, bytes_done, size);
		underflow = 1;
	}

	if (!underflow)
		rc = 0;
	else
		/* allow underflow with -e option */
		rc = -EIO;

out:
	return rc;
}
