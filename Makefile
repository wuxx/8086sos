CFLAGS = -c -Wall -o

all:	clean kernel

clean:	
	rm -f *.bin *.img

kernel:
	nasm -fbin -o boot.bin sos.s
	cat boot.bin > kernel.img


