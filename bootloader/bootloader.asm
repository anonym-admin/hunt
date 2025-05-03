[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x07C0:START                                    ; BIOS 에서 cs 레지스터에 사용하던 값이 남아있을수 있기때문에 초기화를 진행한다








;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 환경설정 값
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







TOTALSECTORCOUNT:   dw  1024                        ; 부트로더를 제외한 os 이미지의 크기







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







START:
    mov ax, 0x07C0
    mov ds, ax                                      ; ds 에는 직접 메모리 값을 넣을 수 없음    
    mov ax, 0xB800                                  ; access video memory
    mov es, ax                                      

    mov ax, 0x0000                                  ; stack 의 시작 어드레스
    mov ss, ax                                      ; ss 세그먼트 레지스터 설정
    mov sp, 0xFFFE
    mov bp, 0xFFFE

    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 화면을 모두 지우고, 속성값을 녹색으로 설정
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    mov si, 0

.SCREENCLEARLOOP:
    mov byte [es:si],    0
    mov byte [es:si+1],  0x0A                       ; Black background and Light green text color

    add si, 2

    cmp si, 80*25*2
    jl  .SCREENCLEARLOOP



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 화면 상단에 시작 메시지 출력
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push    MESSAGE1                               ; 출력할 메시지의 어드레스를 스택에 푸쉬
    push    0                                      ; 화면 y좌표를 스택에 푸쉬
    push    0                                      ; 화면 x좌표를 스택에 푸쉬
    call    PRINTMESSAGE
    add     sp, 6



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; os 이미지 로딩 메시지 출력
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push    IMAGELOADINGMESSAGE
    push    1
    push    0
    call    PRINTMESSAGE
    add     sp, 6



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 디스크에서 os 이미지를 로딩
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESETDISK: ; 디스크를 읽기전 먼저 리셋 진행
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; BIOS RESET FUNCTION 호출
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 서비스 번호: 0, 드라이브 번호(0=Floppy)
    mov ax, 0
    mov dl, 0
    int 0x13
    jc  HANDLEDISKERROR

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 디스크에서 섹터를 읽음
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si, 0x1000
    mov es, si
    mov bx, 0x0000

    mov di, word [TOTALSECTORCOUNT]

READDATA:
    cmp di, 0
    je  READEND
    sub di, 0x1


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; BIOS READ FUNCTION 호출
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ah, 0x02    ; BIOS 서비스 번호 2(READ SECTOR)
    mov al, 0x01
    mov ch, byte [TRACKNUMBER]
    mov cl, byte [SECTORNUMBER]
    mov dh, byte [HEADNUMBER]
    mov dl, 0x00
    int 0x13
    jc HANDLEDISKERROR



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 복사할 어드레스와 트랙 헤드 섹터 어드레스 계산
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    add si, 0x0020  ; add 512byte
    mov es, si

    ; 한 섹터를 읽었으므로, 섹터 번호를 증가시키고, 마지막 섹터(18)까지 읽었는지를 판단한다.
    mov al, byte [SECTORNUMBER]
    add al, 0x01
    mov byte [SECTORNUMBER], al
    cmp al, 19
    jl  READDATA

    ; 마지막 섹터까지 읽었다면 헤드 값을 토글 시킨다.
    ; 섹터 값도 1로 초기화
    xor byte [HEADNUMBER], 0x01
    mov byte [SECTORNUMBER], 1

    ; 만약 헤드 번호가 1 -> 0 이라면 양면의 헤드를 다 읽은것이므로, 트랙을 하나 증가시킨다.
    cmp byte [HEADNUMBER], 0x00
    jne READDATA

    add byte [TRACKNUMBER], 0x01
    jmp READDATA
READEND:



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; OS 이미지가 완료되었다는 메시지를 출력
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push    LOADINGCOMPLETEMESSAGE
    push    1
    push    20
    call    PRINTMESSAGE
    add     sp, 6



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 로딩한 가상 OS 이미지 실행
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp 0x1000:0x0000







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 함수 코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







; 디스크 에러를 처리하는 함수
HANDLEDISKERROR:
    push    DISKERRORMESSAGE    ; 에러 문자열의 어드레스를 스택에 푸쉬
    push    1                   ; 화면의 y 좌표를 스택에 푸쉬
    push    20                  ; 화면의 x 좌표를 스택에 푸쉬
    call    PRINTMESSAGE        ; PRINTMESSAGE 함수 호출

    jmp     $                   ; 현재 위치에서 무한루프 수행

; 메시지를 출력하는 함수
; PARAM: x좌표, y좌표, 문자열
PRINTMESSAGE:
    push    bp                  ; 베이스 포인터 레지스터를 스택에 푸쉬
    mov     bp, sp              ; 베이스 포인터 레지스터에 스택 프레임 레지스터의 값을 설정

    push    es
    push    si
    push    di
    push    ax
    push    cx
    push    dx

    ; es 세그먼트 레지스터에 비디오 모드 어드레스 설정
    ; TODO: 스택의 영역과 곂지는 영역이 발생할 것 같은데, 괜찮은지??
    ; TODO: 앞서서 했던 절차인데 또 하는 이유는??
    mov     ax, 0xB800
    mov     es, ax

    ; x,y좌표로 비디오 메모리의 어드레스 계산
    mov     ax, word [bp+6]                         ; paramerter 2 (y좌표) 에 접근
    mov     si, 160
    mul     si                                      ; ax = ax * si
    mov     di, ax

    mov     ax, word [bp+4]                         ; paramerter 1 (x좌표) 에 접근
    mov     si, 2
    mul     si
    add     di, ax                                  ; di = di + ax

    ; 출력할 문자의 어드레스를 지정
    mov     si, word [bp+8]

.MESSAGELOOP:
    mov cl, byte [si]

    cmp cl, 0
    je  .MESSAGEEND

    mov byte [es:di], cl

    add si, 1
    add di, 2                                       ; +2를 해서 컬러값을 건너뛴다

    jmp .MESSAGELOOP

.MESSAGEEND:
    pop dx
    pop cx
    pop ax
    pop di
    pop si
    pop es
    pop bp
    ret







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Data Section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







; 부트로더 시작 메시지
MESSAGE1:       db  'hunt os boot loader start~!!', 0  ; print message

DISKERRORMESSAGE:       db  'DISK Error~!!', 0
IMAGELOADINGMESSAGE:    db  'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE: db  'Complete~!!', 0

; 디스크 읽기 관련
SECTORNUMBER:   db  0x02
HEADNUMBER:     db  0x00
TRACKNUMBER:    db  0x00

times   510 - ($ - $$)  db  0x00                        ;

db  0x55                                                ; marking boot sector
db  0xAA                                                ; marking boot sector

