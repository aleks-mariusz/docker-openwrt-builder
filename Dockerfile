FROM alpine:3.19

RUN apk add \
        argp-standalone \
        asciidoc \
        bash \
        bc \
        binutils \
        bzip2 \
        cdrkit \
        coreutils \
        curl \
        diffutils \
        findutils \
        flex \
        fts-dev \
        g++ \
        gawk \
        gcc \
        gettext \
        git \
        grep \
        gzip \
        intltool \
        libxslt \
        linux-headers \
        make \
        musl-libintl \
        musl-obstack-dev \
        ncurses-dev \
        openssl-dev \
        patch \
        perl \
        python3-dev \
        rsync \
        sudo \
        tar \
        unzip \
        util-linux \
        wget \
        zlib-dev \
    && ln -s /usr/lib/libncurses.so /usr/lib/libtinfo.so

RUN addgroup \
        -g 9999 \
        -S user \
    && adduser \
        -D \
        -G user \
        -u 9999 \
        user \
    && echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

USER user
WORKDIR /home/user

# set dummy git config
RUN git config --global user.name "user" && git config --global user.email "user@example.com"

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start"]
