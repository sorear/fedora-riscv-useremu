FROM alpine:3.7
RUN apk -U add gcc libc-dev
ADD checksetup.c .
RUN gcc -o checksetup -O2 -static checksetup.c && \
    strip checksetup
