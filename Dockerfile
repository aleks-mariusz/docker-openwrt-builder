FROM alpine:3.18

RUN apk add \
        bash \
        bsd-compat-headers \
        build-base \
        bzip2 \
        coreutils \
        curl \
        diffutils \
        diffutils \
        file \
        findutils \
        gawk \
        git \
        grep \
        less \
        ncurses-dev \
        patch \
        perl \
        python2 \
        python3 \
        rsync \
        sudo \
        tar \
        unzip \
        wget \
        zlib-dev \
    && \
    addgroup -S user && \
    adduser -D -G user user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

USER user
WORKDIR /home/user

# set dummy git config
RUN git config --global user.name "user" && git config --global user.email "user@example.com"
