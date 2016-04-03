CFLAGS = -c -Wall -o

all: kernel

clean:	
	-rm -f *.bin *.img

kernel:
	nasm -fbin -o kernel.bin sos.s
	cp kernel.bin kernel.img

disasm:
	ndisasm kernel.img | less


