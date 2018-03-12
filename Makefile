DOCKER_REPO=sorear/fedora-riscv-wip
DOCKER=sudo docker

all: out/stamp-docker

out/qemu-riscv64: qemu-riscv64/Dockerfile qemu-riscv64/musl-build.patch
	$(DOCKER) build -t sorear/qemu-riscv64 qemu-riscv64
	$(DOCKER) run --rm sorear/qemu-riscv64 cat riscv-qemu/riscv64-linux-user/qemu-riscv64 > $@
	chmod +x $@

out/checksetup: checksetup/Dockerfile checksetup/checksetup.c
	$(DOCKER) build -t sorear/checksetup checksetup
	$(DOCKER) run --rm sorear/checksetup cat checksetup > $@
	chmod +x $@

out/stage4-disk.img.xz:
	rm -f $@ $@-t
	wget -O $@-t https://fedorapeople.org/groups/risc-v/disk-images/stage4-disk.img.xz
	mv $@-t $@

out/stamp-docker-bare: out/stage4-disk.img.xz
	unxz -k out/stage4-disk.img.xz
	virt-tar-out -a out/stage4-disk.img / - | $(DOCKER) import - $(DOCKER_REPO):bare-latest
	$(DOCKER) tag $(DOCKER_REPO):bare-latest $(DOCKER_REPO):bare-$$(date -u +%F-%H%M)
	rm out/stage4-disk.img
	touch $@

out/stamp-docker: out/stamp-docker-bare out/qemu-riscv64 out/checksetup fedora-riscv/Dockerfile
	mkdir -p fedora-riscv/tree/usr/bin fedora-riscv/tree/etc/yum.repos.d
	cp out/checksetup fedora-riscv/tree/checksetup
	cp out/qemu-riscv64 fedora-riscv/tree/usr/bin/qemu-riscv64
	#cp riscv.repo fedora-riscv/tree/etc/yum.repos.d/riscv.repo
	$(DOCKER) build -t $(DOCKER_REPO):latest fedora-riscv
	$(DOCKER) tag $(DOCKER_REPO):latest $(DOCKER_REPO):$$(date -u +%F-%H%M)
	touch $@
