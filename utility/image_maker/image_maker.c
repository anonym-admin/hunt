#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/io.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <unistd.h>

#define BYTESOFSECTOR   512

int adjust_in_sector_size(int fd, int source_size);
void write_kernel_information(int tar_fd, int kernel_sector_count);
int copy_file(int src_fd, int tar_fd);

int main(int argc, char* argv[])
{
    int source_fd;
    int target_fd;
    int bootloader_size;
    int kernel32_sector_count;
    int source_size;

    if(argc < 3)
    {
        fprintf(stderr, "[ERROR] image_maker bootloader.bin kernel32.bin\n");
        exit(-1);
    }

    if((target_fd = open("disk.img", O_RDWR | O_CREAT | O_TRUNC)) == -1)
    {
        fprintf(stderr, "[ERROR] disk.img open failed\n");
        exit(-1);
    }

    printf("[INFO] Copy boot loader to image file\n");
    if((source_fd = open(argv[1], O_RDONLY)) == -1)
    {
        fprintf(stderr, "[ERROR] %s open failed\n", argv[1]);
        exit(-1);
    }

    source_size = copy_file(source_fd, target_fd);
    close(source_fd);

    bootloader_size = adjust_in_sector_size(target_fd, source_size);
    printf("[INFO] %s size = [%d] and sector count = [%d]\n", argv[1], source_size, bootloader_size);

    printf("[INFO] Copy protected mode to image file\n");
    if((source_fd = open(argv[2], O_RDONLY)) == -1)
    {
        fprintf(stderr, "[ERROR] %s open failed\n", argv[2]);
        exit(-1);
    }

    source_size = copy_file(source_fd, target_fd);
    close(source_fd);
    
    kernel32_sector_count = adjust_in_sector_size(target_fd, source_size);
    printf("[INFO] %s size = [%d] and sector count = [%d]\n", argv[2], source_size, kernel32_sector_count);

    printf("[INFO] Start to write kernel information\n");
    write_kernel_information(target_fd, kernel32_sector_count);
    printf("[INFO] Image file create complete\n");

    close(target_fd);
    return 0;
}

int adjust_in_sector_size(int fd, int source_size)
{
    int i;
    int adjust_size_to_sector;
    char ch;
    int sector_count;

    adjust_size_to_sector = source_size % BYTESOFSECTOR;
    ch = 0x00;

    if(adjust_size_to_sector != 0)
    {
        adjust_size_to_sector = BYTESOFSECTOR - adjust_size_to_sector;
        printf("[INFO] File size[%d] and fill [%u] byte\n", source_size, adjust_size_to_sector);
        for(i = 0; i < adjust_size_to_sector; i++)
        {
            write(fd, &ch, 1);
        }
    }
    else
    {
        printf("[INFO] File size is aligned 512 byte\n");
    }
    sector_count = (source_size + adjust_size_to_sector) / BYTESOFSECTOR;
    return sector_count;
}

void write_kernel_information(int tar_fd, int kernel_sector_count)
{
    unsigned short data;
    long position;

    position = lseek(tar_fd, 5, SEEK_SET);
    if(position == -1)
    {
        fprintf(stderr, "lseek fail. return = %ld, errno = %d, %d\n", position, errno, SEEK_SET);
        exit(-1);
    }

    data = (unsigned short)kernel_sector_count;
    write(tar_fd, &data, 2);

    printf("[INFO] Total sector count except boot loader [%d]\n", kernel_sector_count);
}

int copy_file(int src_fd, int tar_fd)
{
    int source_file_size;
    int read_byte;
    int write_byte;
    char buf[BYTESOFSECTOR];

    source_file_size = 0;
    while(1)
    {
        read_byte = read(src_fd, buf, sizeof(buf));
        write_byte = write(tar_fd, buf, read_byte);

        if(read_byte != write_byte)
        {
            fprintf(stderr, "[ERROR] read != write\n");
            exit(-1);
        }
        source_file_size += read_byte;

        if(read_byte != sizeof(buf))
        {
            break;
        }
    }

    return source_file_size;
}