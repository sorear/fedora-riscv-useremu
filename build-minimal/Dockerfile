FROM sorear/fedora-riscv-wip:minimal-bare-latest

COPY tree /
# workaround problems with the gcc and glibc builds
RUN ln -s /bin/gcc /bin/cc && \
    ln -s /lib64/gconv /lib/gconv && \
    rm -f /etc/yum.repos.d/fedora* /etc/yum.repos.d/local.repo
ENTRYPOINT ["/checksetup"]
