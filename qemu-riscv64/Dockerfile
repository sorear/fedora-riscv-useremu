FROM alpine:3.7
RUN apk -U add git gcc make unzip python libc-dev zlib-dev linux-headers glib-dev glib-static pixman-dev unzip
ADD https://github.com/riscv/riscv-qemu/archive/6256f8ac6004677cc4652b1fcd77c839dfc05015.zip riscv-qemu.zip
ADD musl-build.patch .
RUN unzip riscv-qemu.zip && \
    mv riscv-qemu-6256f8ac6004677cc4652b1fcd77c839dfc05015 riscv-qemu && \
    cd riscv-qemu && \
    patch -p1 < /musl-build.patch && \
    ./configure --target-list=riscv64-linux-user --disable-werror --static --disable-capstone && \
    make -j4 && \
    strip riscv64-linux-user/qemu-riscv64
