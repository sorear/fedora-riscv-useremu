DOCKER_REPO=sorear/fedora-riscv-wip

all: stamp-docker-full stamp-docker-minimal

stage4-disk.img.xz:
	rm -f $@ $@-t
	wget -O $@-t https://fedorapeople.org/groups/risc-v/disk-images/stage4-disk.img.xz
	mv $@-t $@

stage4-full-fat-disk.img.xz:
	rm -f $@ $@-t
	wget -O $@-t https://fedorapeople.org/groups/risc-v/disk-images/stage4-full-fat-disk.img.xz
	mv $@-t $@

# configure script seems buggy and detects libraries that can't be statically linked
qemu-riscv64:
	rm -rf $@ riscv-qemu
	git clone -b devel https://github.com/sorear/riscv-qemu
	cd riscv-qemu && mkdir build && cd build && ../configure --static --target-list=riscv64-linux-user --disable-libnfs --disable-nettle --disable-gnutls --disable-libiscsi --disable-glusterfs --disable-libssh2 --disable-uuid && $(MAKE)
	cp riscv-qemu/build/riscv64-linux-user/qemu-riscv64 $@

stamp-docker-full-bare:
	unxz -k stage4-full-fat-disk.img.xz
	virt-tar-out -a stage4-full-fat-disk.img / - excludes:'0ad-data-*' | docker import - $(DOCKER_REPO):full-bare-latest
	docker tag $(DOCKER_REPO):full-bare-latest $(DOCKER_REPO):full-bare-$$(date -u +%F-%H%M)
	rm stage4-full-fat-disk.img
	touch $@

stamp-docker-minimal-bare:
	unxz -k stage4-disk.img.xz
	virt-tar-out -a stage4-disk.img / - | docker import - $(DOCKER_REPO):minimal-bare-latest
	docker tag $(DOCKER_REPO):minimal-bare-latest $(DOCKER_REPO):minimal-bare-$$(date -u +%F-%H%M)
	rm stage4-disk.img
	touch $@

checksetup: checksetup.c
	cc -o $@ -static $<

stamp-docker-full: checksetup qemu-riscv64 stamp-docker-full-bare
	cp checksetup qemu-riscv64 build-full/
	docker build -t $(DOCKER_REPO):full build-full
	docker tag $(DOCKER_REPO):full $(DOCKER_REPO):full-$$(date -u +%F-%H%M)
	docker tag $(DOCKER_REPO):full $(DOCKER_REPO):latest
	touch $@

stamp-docker-minimal: checksetup qemu-riscv64 stamp-docker-minimal-bare
	cp checksetup qemu-riscv64 build-minimal/
	docker build -t $(DOCKER_REPO):minimal build-minimal
	docker tag $(DOCKER_REPO):minimal $(DOCKER_REPO):minimal-$$(date -u +%F-%H%M)
	touch $@
