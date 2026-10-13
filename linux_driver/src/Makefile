CC := aarch64-buildroot-linux-gnu-gcc
LIBS := -lrt
CFLAGS := -std=c99 -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGE_FILE_SOURCE
SRC := $(wildcard *.c)
OBJ := $(SRC:.c=.o)
TARGET := pcie_bdma_transfer_demo
all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(LIBS) -o $@ $^ $(CFLAGS)

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

clean:
	rm -rf *.o $(TARGET)

.PHONY: all clean
