DOCKER_REPO=sorear/fedora-riscv-wip

all: stamp-docker-minimal

stage4-disk.img.xz:
	rm -f $@ $@-t
	wget -O $@-t https://fedorapeople.org/groups/risc-v/disk-images/stage4-disk.img.xz
	mv $@-t $@

# configure script seems buggy and detects libraries that can't be statically linked
qemu-riscv64-arsv:
	rm -rf $@ riscv-qemu-arsv
	git clone -b devel https://github.com/sorear/riscv-qemu riscv-qemu-arsv
	cd riscv-qemu-arsv && mkdir build && cd build && ../configure --static --target-list=riscv64-linux-user --disable-libnfs --disable-nettle --disable-gnutls --disable-libiscsi --disable-glusterfs --disable-libssh2 --disable-uuid && $(MAKE)
	cp riscv-qemu-arsv/build/riscv64-linux-user/qemu-riscv64 $@

# configure script seems buggy and detects libraries that can't be statically linked
qemu-riscv64:
	rm -rf $@ riscv-qemu
	git clone https://github.com/riscv/riscv-qemu riscv-qemu
	cd riscv-qemu && mkdir build && cd build && ../configure --static --target-list=riscv64-linux-user --disable-libnfs --disable-nettle --disable-gnutls --disable-libiscsi --disable-glusterfs --disable-libssh2 --disable-uuid && $(MAKE)
	cp riscv-qemu/build/riscv64-linux-user/qemu-riscv64 $@

stamp-docker-minimal-bare: stage4-disk.img.xz
	unxz -k stage4-disk.img.xz
	virt-tar-out -a stage4-disk.img / - | docker import - $(DOCKER_REPO):minimal-bare-latest
	docker tag $(DOCKER_REPO):minimal-bare-latest $(DOCKER_REPO):minimal-bare-$$(date -u +%F-%H%M)
	rm stage4-disk.img
	touch $@

checksetup: checksetup.c
	cc -o $@ -static $<

stamp-docker-minimal: checksetup qemu-riscv64 qemu-riscv64-arsv stamp-docker-minimal-bare
	mkdir -p build-minimal/tree/usr/bin build-minimal/tree/etc/yum.repos.d
	strip checksetup -o build-minimal/tree/checksetup
	strip qemu-riscv64-arsv -o build-minimal/tree/usr/bin/qemu-riscv64-arsv
	strip qemu-riscv64 -o build-minimal/tree/usr/bin/qemu-riscv64
	cp riscv.repo build-minimal/tree/etc/yum.repos.d/riscv.repo
	docker build -t $(DOCKER_REPO):minimal build-minimal
	docker tag $(DOCKER_REPO):minimal $(DOCKER_REPO):minimal-$$(date -u +%F-%H%M)
	docker tag $(DOCKER_REPO):minimal $(DOCKER_REPO):latest
	touch $@
