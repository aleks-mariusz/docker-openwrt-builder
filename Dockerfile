FROM alpine:3.21

RUN apk add \
        argp-standalone \
        bash \
        bzip2 \
        coreutils \
        curl \
        diffutils \
        findutils \
        file \
        g++ \
        gawk \
        gcc \
        git \
        grep \
        gzip \
        make \
        linux-headers \
        musl-fts-dev \
        musl-libintl \
        musl-obstack-dev \
        ncurses-dev \
        patch \
        perl \
        py3-setuptools \
        python3-dev \
        rsync \
        sudo \
        swig \
        tar \
        unzip \
        wget \
        zlib-dev \
        zstd

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
