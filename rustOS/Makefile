FILES = build/kernel.asm.o build/kernel.o
INCLUDES = -I src/
FLAGS = -g -ffreestanding -falign-jumps -falign-functions -falign-labels \
	-falign-loops -fstrength-reduce -fomit-frame-pointer -finline-functions \
	-Wno-unused-functions -fno-builtin -Werror -Wno-unused-label -Wno-cpp \
	-Wno-unused-parameter -nostdlib -nostartfiles -nodefaultlibs -Wall -O0 -Iinc

all: bin/boot.bin bin/kernel.bin
	rm -f bin/os.bin
	dd if=bin/boot.bin >> bin/os.bin
	dd if=bin/kernel.bin >> bin/os.bin
	dd if=/dev/zero bs=512 count=100 >> bin/os.bin

bin/kernel.bin: $(FILES)
	i686-elf-ld -g -relocatable $(FILES) -o build/kernelfull.o
	i686-elf-gcc $(FLAGS) -T src/linker.ld -o bin/kernel.bin -ffreestanding -O0 -nostdlib build/kernelfull.o

bin/boot.bin: src/boot/boot.asm
	nasm -f bin src/boot/boot.asm -o bin/boot.bin

build/kernel.asm.o: src/kernel.asm
	nasm -f elf -g src/kernel.asm -o build/kernel.asm.o

build/kernel.o: src/kernel.rs 
	rustc -C opt-level=0 -g src/kernel.rs --emit=obj -o build/kernel.o --target=riscv32imc-unknown-none-elf	

clean:
	rm -f bin/boot.bin bin/kernel.bin bin/os.bin
	rm -f build/kernelfull.o
	rm -f $(FILES)
