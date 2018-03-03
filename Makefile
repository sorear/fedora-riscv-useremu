DOCKER_REPO=sorear/fedora-riscv-wip

all: stamp-docker-minimal

bin/qemu-riscv64: qemu-riscv64/Dockerfile qemu-riscv64/musl-build.patch
	docker build -t sorear/qemu-riscv64 qemu-riscv64
	docker run --rm sorear/qemu-riscv64 cat riscv-qemu/riscv64-linux-user/qemu-riscv64 > $@
	chmod +x $@

bin/checksetup: checksetup/Dockerfile checksetup/checksetup.c
	docker build -t sorear/checksetup checksetup
	docker run --rm sorear/checksetup cat checksetup > $@
	chmod +x $@

stage4-disk.img.xz:
	rm -f $@ $@-t
	wget -O $@-t https://fedorapeople.org/groups/risc-v/disk-images/stage4-disk.img.xz
	mv $@-t $@

stamp-docker-minimal-bare: stage4-disk.img.xz
	unxz -k stage4-disk.img.xz
	virt-tar-out -a stage4-disk.img / - | docker import - $(DOCKER_REPO):minimal-bare-latest
	docker tag $(DOCKER_REPO):minimal-bare-latest $(DOCKER_REPO):minimal-bare-$$(date -u +%F-%H%M)
	rm stage4-disk.img
	touch $@

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
