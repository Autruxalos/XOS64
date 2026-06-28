# =============================================================================
# MAKEFILE INTEGRADO CON SISTEMA DE ARCHIVOS EXFS64
# =============================================================================

all: build/xos64.img

build/xboot.bin: src/boot/xboot.asm
	mkdir -p build
	nasm -f bin src/boot/xboot.asm -o build/xboot.bin

build/xkernel.bin: src/kernel/xkernel.asm
	nasm -f bin src/kernel/xkernel.asm -o build/xkernel.bin

build/exfs64_dir.bin: src/boot/exfs64_dir.asm
	nasm -f bin src/boot/exfs64_dir.asm -o build/exfs64_dir.bin

build/xsh.bin: src/apps/xsh.asm
	nasm -f bin src/apps/xsh.asm -o build/xsh.bin

build/exit.bin: src/init/exit.asm
	nasm -f bin src/init/exit.asm -o build/exit.bin

build/xos64.img: build/xboot.bin build/xkernel.bin build/exfs64_dir.bin build/xsh.bin build/exit.bin
	# 1. Forzar tamaños exactos en bloques múltiplos de 512 bytes
	truncate -s 512  build/xboot.bin
	truncate -s 4096 build/xkernel.bin
	truncate -s 512  build/exfs64_dir.bin
	truncate -s 4096 build/xsh.bin
	truncate -s 512  build/exit.bin
	
	# 2. Ensamblar la imagen lineal del disco (Geometría EXFS64)
	# Sector 0: XBOOT (512b)
	# Sectores 1-8: XKERNEL (4096b)
	# Sector 9: Directorio EXFS64 (512b)
	# Sectores 10-17: XSH (4096b)
	# Sector 18: EXIT (512b)
	cat build/xboot.bin build/xkernel.bin build/exfs64_dir.bin build/xsh.bin build/exit.bin > build/xos64.img
	truncate -s 10M build/xos64.img

run: build/xos64.img
	qemu-system-x86_64 -drive format=raw,file=build/xos64.img

clean:
	rm -rf build/
