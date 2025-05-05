# all is default target.
all: boot kernel_32 disk.img 

boot: 
	@echo 
	@echo ======= build boot loader =======
	@echo

# excute bootloader directory make file.
	make -C bootloader

	@echo
	@echo ======= build complete =======
	@echo

kernel_32:
	@echo
	@echo ======= build 32bit kernel =======
	@echo

	make -C kernel32

	@echo
	@echo ======= build complete =======
	@echo

disk.img: bootloader/bootloader.bin kernel32/kernel32.bin
	@echo 
	@echo ======= disk image build start =======
	@echo

	./image_maker.out $^

	@echo 
	@echo ======= all build complete =======
	@echo

clean:
	make -C bootloader clean
	make -C kernel32 clean
	rm -f disk.img

