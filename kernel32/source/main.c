#include "types.h"

// void print_string(int x, int y, const char* text);

void hmain()
{
    // print_string(0, 3, "c language kernel started~!!!");

    while(1);
}

void print_string(int x, int y, const char* text)
{
    struct charactor_struct* screen = (struct charactor_struct*)0xB8000;
    int i;

    screen += (y * 80) + x;
    for (i = 0; text[i] != 0; i++)
    {
        screen[i].charactor = text[i];
    }
}