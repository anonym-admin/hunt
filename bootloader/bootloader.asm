[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x07C0:START                                    ; BIOS 에서 cs 레지스터에 사용하던 값이 남아있을수 있기때문에 초기화를 진행한다

START:
    mov ax, 0x07C0
    mov ds, ax                                      ; ds 에는 직접 메모리 값을 넣을 수 없음    
    mov ax, 0xB800                                  ; access video memory
    mov es, ax                                      
    
    mov si, 0

.SCREENCLEARLOOP:
    mov byte [es:si],    0
    mov byte [es:si+1],  0x0A                       ; Black background and Light green text color

    add si, 2

    cmp si, 80*25*2
    jl  .SCREENCLEARLOOP

    mov si, 0
    mov di, 0

.MESSAGELOOP:
    mov cl, byte [MESSAGE1+si]

    cmp cl, 0
    je  .MESSAGEEND

    mov byte [es:di], cl

    add si, 1
    add di, 2                                       ; +2를 해서 컬러값을 건너뛴다

    jmp .MESSAGELOOP

.MESSAGEEND:
    jmp $                                           ; loop

MESSAGE1:   db  'hunt os boot loader start~!!', 0   ; print message

times   510 - ($ - $$)  db  0x00                    ;

db  0x55                                            ; marking boot sector
db  0xAA                                            ; marking boot sector

