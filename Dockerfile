FROM debian:trixie AS dev-env

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV FPC_VERSION=3.2.2
ENV FPC_SRC=/opt/fpcbuild-3.2.2/fpcsrc
ENV FPC_CROSS_PREFIX=/opt/fpc-cross
ENV PATH=/opt/fpc-cross/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    binutils \
    ca-certificates \
    curl \
    dosbox \
    file \
    fpc \
    fpc-source \
    make \
    mtools \
    nasm \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspaces/uniflash

RUN mkdir -p /opt/fpc-cross

RUN curl -fsSL "https://downloads.sourceforge.net/project/freepascal/Source/${FPC_VERSION}/fpcbuild-${FPC_VERSION}.tar.gz" \
    | tar -xzf - -C /opt

COPY scripts/bootstrap-fpc-cross.sh /usr/local/bin/bootstrap-fpc-cross
RUN chmod 755 /usr/local/bin/bootstrap-fpc-cross \
    && bootstrap-fpc-cross \
    && cd "$FPC_SRC/rtl/msdos" \
    && nasm -f obj -o prt0s.o prt0s.asm \
    && nasm -f obj -o prt0l.o prt0l.asm \
    && nasm -f obj -o prt0h.o prt0h.asm

CMD ["bash"]