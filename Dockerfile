FROM debian:trixie-slim

ARG OW2_RELEASE=2026-07-13-Build
ARG OW2_SHA256=35e9c56ca93234ba0b8b596387815399317ea0548aeac1318f0674dca3921314

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV WATCOM=/opt/watcom
ENV EDPATH=/opt/watcom/eddat
ENV INCLUDE=/opt/watcom/h
ENV PATH=/opt/watcom/binl64:/opt/watcom/binl:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        file \
        make \
        zip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN test "$(dpkg --print-architecture)" = amd64

RUN curl -fsSL \
        "https://github.com/open-watcom/open-watcom-v2/releases/download/${OW2_RELEASE}/ow-snapshot.tar.xz" \
        -o /tmp/ow-snapshot.tar.xz \
    && echo "${OW2_SHA256}  /tmp/ow-snapshot.tar.xz" | sha256sum -c - \
    && mkdir -p "${WATCOM}" \
    && tar -xJf /tmp/ow-snapshot.tar.xz -C "${WATCOM}" \
    && rm -f /tmp/ow-snapshot.tar.xz

COPY scripts/verify-openwatcom.sh /usr/local/bin/verify-openwatcom
RUN chmod 755 /usr/local/bin/verify-openwatcom

WORKDIR /workspaces/uniflash

CMD ["bash"]
