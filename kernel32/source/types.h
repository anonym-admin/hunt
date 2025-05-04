#ifndef __TYPE_H__
#define __TYPE_H__

#define BYTE    unsigned char
#define WORD    unsigned short
#define DWORD   unsigned int
#define QWORD   unsigned long
#define BOOL    unsigned char

#define TRUE    1
#define FALSE   0
#define NULL    0

// 비디오 모드 중 텍스트 모드 화면을 구성하는 자료구조
#pragma pack(push, 1)
struct charactor_struct
{
    BYTE charactor;
    BYTE attribute;
};
#pragma pack(pop)

#endif