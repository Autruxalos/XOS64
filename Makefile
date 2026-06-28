# =============================================================================
# MAKEFILE XOS64 - BLINDADO CONTRA FALLOS DE ARRANQUE MBR
# =============================================================================

all: build/XOS64.img

build/xboot64.bin: src/boot/xboot64.asm
	mkdir -p build
	nasm -f bin src/boot/xboot64.asm -o build/xboot64.bin

build/xkernel64.bin: src/kernel/xkernel64.asm
	mkdir -p build
	nasm -f bin src/kernel/xkernel64.asm -o build/xkernel64.bin

build/exfs64-dir.bin: src/boot/exfs64-dir.asm
	mkdir -p build
	nasm -f bin src/boot/exfs64-dir.asm -o build/exfs64-dir.bin

build/xsh64.bin: src/apps/xsh64.asm
	mkdir -p build
	nasm -f bin src/apps/xsh64.asm -o build/xsh64.bin

build/exit64.bin: src/init/exit64.asm
	mkdir -p build
	nasm -f bin src/init/exit64.asm -o build/exit64.bin

build/XOS64.img: build/xboot64.bin build/xkernel64.bin build/exfs64-dir.bin build/xsh64.bin build/exit64.bin
	# 1. Forzar tamaños exactos del sistema de archivos EXFS64 (Excepto el bootloader que ya mide 512)
	truncate -s 4096 build/xkernel64.bin
	truncate -s 512  build/exfs64-dir.bin
	truncate -s 4096 build/xsh64.bin
	truncate -s 512  build/exit64.bin
	
	# 2. Concatenar de forma lineal limpia en la imagen definitiva (XOS64.img en mayúsculas)
	cat build/xboot64.bin build/xkernel64.bin build/exfs64-dir.bin build/xsh64.bin build/exit64.bin > build/XOS64.img
	truncate -s 10M build/XOS64.img

run: build/XOS64.img
	# Forzar a QEMU a leer la imagen como un disco duro crudo (Raw Hard Disk)
	qemu-system-x86_64 -drive format=raw,file=build/XOS64.img

clean:
	rm -rf build/
