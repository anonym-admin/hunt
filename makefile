# all is default target.
all: boot disk.img 

boot: 
	@echo 
	@echo ======= build boot loader =======
	@echo

# excute bootloader directory make file.
	make -C bootloader

	@echo
	@echo ======= build complete =======
	@echo

disk.img: bootloader/bootloader.bin
	@echo 
	@echo ======= disk image build start =======
	@echo

	cp bootloader/bootloader.bin disk.img

	@echo 
	@echo ======= all build complete =======
	@echo

clean:
	make -C bootloader clean
	rm -f disk.img

