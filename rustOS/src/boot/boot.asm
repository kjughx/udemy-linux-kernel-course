org 0x7c00
BITS 16

CODE_SEG equ gdt_code - gdt_start 
DATA_SEG equ gdt_data - gdt_start

_start:
    jmp short start
    nop

times 33 db 0

start:
    jmp 0:step2

step2:
    cli ; clear interrupts
        mov ax, 0x00
        mov ds, ax ; data segment
        mov es, ax ; extra segment
        mov ss, ax ; stack segment
        mov sp, 0x7c00 ; stack pointer
    sti  ; enable interrupts

.load_protected:
    cli 
        lgdt[gdt_descriptor] 
        mov eax, cr0
        or eax, 0x1
        mov cr0, eax
        jmp CODE_SEG:load32
        jmp $
    sti 

; GDT
gdt_start:

gdt_null:
    dd 0x0
    dd 0x0

; offset 0x8
gdt_code:     ; CS SHOULD POINT TO THIS
; all default values
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0      ; Base first 0-15 bits
    db 0      ; Base 16-23 bits
    db 0x9a   ; access byte
    db 11001111b ; High 4 bit flags and low 4 bit flags
    db 0      ; Base 24-31 bits

; offset 0x10
gdt_data: ; DS, SS, ES, FS, GS SHOULD POINT TO THIS
; all default values
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0      ; Base first 0-15 bits
    db 0      ; Base 16-23 bits
    db 0x92   ; access byte
    db 11001111b ; High 4 bit flags and low 4 bit flags
    db 0      ; Base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start-1
    dd gdt_start

[BITS 32]
load32:
    mov eax, 1
    mov ecx, 100
    mov edi, 0x0100000
    call ata_lba_read 
    jmp CODE_SEG:0x0100000

ata_lba_read:
    mov ebx, eax ; Backup the LBA
    ; Send the highest 8bits of the lba to the hard disk controller
    shr eax, 24
    or eax, 0xE0 ; Select master drive
    mov dx, 0x1F6
    out dx, al
    ; Finished sending highest 8 bits

    ; Send total sectors to read
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al
    ; Finished sending total sectors

    ; Send more bits of the lba
    mov eax, ebx ; Restore backup lba
    mov dx, 0x1F3
    out dx, al ; writes to bus
    ; Finished sending 

    ; send more bits
    mov eax, ebx ; Restore backup lba
    mov dx, 0x1F4
    shr eax, 8
    out dx, al
    ; finished sending more bits

    ; send upper 16 bits of the lba
    mov dx, 0x1F5
    mov eax, ebx ; restore lba
    shr eax, 16
    out dx, al
    ; finsihed

    mov dx, 0x1F7
    mov al, 0x20
    out dx, al

    ; read all sectors
.next_sector:
    push ecx

.try_again: ; checking if we need to read
    mov dx, 0x1f7
    in al, dx
    test al, 8
    jz .try_again
; need to read 256 words at a time
    mov ecx, 256
    mov dx, 0x1F0
    rep insw

    pop ecx 
    loop .next_sector
    ;end of reading sectors
    ret 

times 510-($ - $$) db 0 ; want program to be 510 bytes, pads remaining data
dw 0xAA55 ; last two bytes should be 55AA, little endian -> reverse order