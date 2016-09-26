FROM sorear/fedora-riscv-wip:minimal-bare-latest

COPY checksetup /checksetup
COPY qemu-riscv64 /usr/bin/qemu-riscv64
ENTRYPOINT ["/checksetup"]
