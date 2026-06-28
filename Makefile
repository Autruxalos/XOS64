# =============================================================================
# MAKEFILE INTEGRADO CON SISTEMA DE ARCHIVOS EXFS64
# =============================================================================

all: build/xos64.img

build/xboot.bin: src/boot/xboot64.asm
	mkdir -p build
	nasm -f bin src/boot/xboot64.asm -o build/xboot.bin

build/xkernel.bin: src/kernel/xkernel64.asm
	nasm -f bin src/kernel/xkernel.asm -o build/xkernel.bin

build/exfs64_dir.bin: src/boot/exfs64_dir.asm
	nasm -f bin src/boot/exfs64-dir.asm -o build/exfs64_dir.bin

build/xsh.bin: src/apps/xsh64.asm
	nasm -f bin src/apps/xsh64.asm -o build/xsh.bin

build/exit.bin: src/init/exit64.asm
	nasm -f bin src/init/exit64.asm -o build/exit.bin

build/xos64.img: build/xboot64.bin build/xkernel.bin build/exfs64_dir.bin build/xsh.bin build/exit.bin
	# 1. Forzar tamaños exactos en bloques múltiplos de 512 bytes
	truncate -s 512  build/xboot64.bin
	truncate -s 4096 build/xkernel64.bin
	truncate -s 512  build/exfs64-dir.bin
	truncate -s 4096 build/xsh64.bin
	truncate -s 512  build/exit64.bin
	
	# 2. Ensamblar la imagen lineal del disco (Geometría EXFS64)
	# Sector 0: XBOOT64 (512b)
	# Sectores 1-8: XKERNEL64 (4096b)
	# Sector 9: Directorio EXFS64 (512b)
	# Sectores 10-17: XSH64 (4096b)
	# Sector 18: EXIT64 (512b)
	cat build/xboot64.bin build/xkernel64.bin build/exfs64-dir.bin build/xsh64.bin build/exit64.bin > build/xos64.img
	truncate -s 10M build/xos64.img

run: build/xos64.img
	qemu-system-x86_64 -drive format=raw,file=build/xos64.img

clean:
	rm -rf build/
