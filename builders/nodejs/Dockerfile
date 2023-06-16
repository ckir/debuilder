FROM i386/debian:latest

RUN cat <<EOF > /etc/apt/sources.list
deb https://ftp.debian.org/debian/ bookworm contrib main non-free non-free-firmware
deb-src https://ftp.debian.org/debian/ bookworm contrib main non-free non-free-firmware

deb https://ftp.debian.org/debian/ bookworm-updates contrib main non-free non-free-firmware
deb-src https://ftp.debian.org/debian/ bookworm-updates contrib main non-free non-free-firmware

deb https://ftp.debian.org/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware
deb-src https://ftp.debian.org/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware

deb https://ftp.debian.org/debian/ bookworm-backports contrib main non-free non-free-firmware
deb-src https://ftp.debian.org/debian/ bookworm-backports contrib main non-free non-free-firmware

deb https://security.debian.org/debian-security/ bookworm-security contrib main non-free non-free-firmware
deb-src https://security.debian.org/debian-security/ bookworm-security contrib main non-free non-free-firmware
EOF

RUN apt-get -qq update \
    && apt-get install -y apt-utils \
    && apt-get install -y \
    build-essential \
    gcc-multilib \
    binutils \
    wget \
    curl \
    awscli \
    dpkg-dev \
    devscripts
COPY ./setup.sh /opt/src/scripts/setup.sh
RUN mkdir /Build /Release && chmod +x /opt/src/scripts/setup.sh
