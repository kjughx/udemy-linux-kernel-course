ORG 0x7c00 ; origin of program in RAM
BITS 16 ; number of bits 

CODE_SEG equ gdt_code - gdt_start 
DATA_SEG equ gdt_data - gdt_start

jmp short start
nop

; fat16 header

OEMIdentifier       db 'PEACHOS '
BytesPerSector      dw 0x200
SectorPerCluster    db 0x80
ReservedSectors     dw 200
FATCopies           db 0x02
RootDirEntries      dw 0x40
NumSectors          dw 0x00
MediaType           db 0xF8
SectorsPerFat       dw 0x100
SectorsPerTrack     dw 0x20
NumberOfHeads       dw 0x40
HiddenSectors       dd 0x00
SectorsBig          dd 0x773594

; Extended BPB 
DriveNumber         db 0x80
WinNTBit            db 0x00
Signature           db 0x29
VolumeID            dd 0xD105
VolumeIDString      db 'PEACHOS BOO'
SystemIDString      db 'FAT16   '


jmp 0:start ; code segment start 

start:
    jmp 0:step2 ; code segment start 
    
step2:
    cli ; Clear interrupts, disables interrupts - about to change memory segments
    mov ax, 0x00 ; have to put here first
    mov ds, ax ; data segment start, as opposed to bios setting it
    mov es, ax ; extra segment start, as opposed to bios setting it
    mov ss, ax ; stack segment starts at 0x00
    mov sp, 0x7c00 ; stack pointer goes backwards, so set at end 0x7c00

    sti ; Enables/set interrupts

.load_protected:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32
    jmp $

; GDT
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0

; offset 0x8
gdt_code:
    dw 0xffff ; segment list first 0-15 bits
    dw 0      ; Base first 0-15 bits
    db 0      ; BAse first 16-23 bits
    db 0x9a   ; Access byte
    db 11001111b ; High 5 bit flgs and low 4 bit flags
    db 0        ; Base 24-31 bits
; offset 0x10
gdt_data: ; DS, SS, ES, FS, GS
    dw 0xffff ; segment list first 0-15 bits
    dw 0      ; Base first 0-15 bits
    db 0      ; BAse first 16-23 bits
    db 0x92   ; Access byte
    db 11001111b ; High 5 bit flgs and low 4 bit flags
    db 0        ; Base 24-31 bits

gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1
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
    ; send highest 8 bits of lba to hard disk controller
    shr eax, 24
    or eax, 0xE0 ; selects the master drive
    mov dx, 0x1F6 ; port expected to read above bits
    out dx, al
    ; finished sending 8 bits

    ; send total sectors to read
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al
    ; finished sending sectors

    ; send more bits of lba
    mov eax, ebx ;restore backup
    mov dx, 0x1F3
    out dx, al ; talks to bus
    ; finsihed sending more bits

    ;send more bits
    mov dx, 0x1F4
    mov eax, ebx ; restore lba 
    shr eax, 8
    out dx, al
    ;finished sending

    ; send upper 16 bits of lba
    mov dx, 0x1F5
    mov eax, ebx ; restore backup
    shr eax, 16 ; shift tor giht by 16
    out dx, al
    ; finished 16 bits

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

;read all sectors in memory
.next_sector:
    push ecx

.try_again: ; check if we need to read
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
    ; end of reading sectors

    ret

times 510-($- $$) db 0 ; fill remaining binary file with 0 to total 512 bytes
dw 0xAA55 ; assemble word 0x55AA into binary file, boot signature
