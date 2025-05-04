all: kernel32.bin

kernel32.bin: source/entry_point.s
	nasm -o kernel32.bin $<

clean:
	rm -f kernel32.bin