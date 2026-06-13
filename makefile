all: disc-log

disc-log: disc-log.o
	gcc -g -m64 -no-pie -o disc-log disc-log.o

disc-log.o: disc-log.asm
	nasm -g -f elf64 -l disc-log.lst disc-log.asm

clean:
	rm -f disc-log disc-log.o disc-log.lst