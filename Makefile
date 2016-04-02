CFLAGS = -c -Wall -o

all:	clean kernel

clean:	
	rm -f *.bin *.img

kernel:
	nasm -fbin -o kernel.img sos.s


