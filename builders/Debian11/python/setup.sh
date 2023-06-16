#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
LATEST_VERSION=$(wget -qO- https://www.python.org | grep -oE 'Latest: .*[0-9]+\.[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "Python's latest available version found is: $LATEST_VERSION"
INSTALL_DIR="python_$LATEST_VERSION-1_i386"
PACKAGE_NAME="$INSTALL_DIR.deb"
BUILD_STORE="https://ckir-debuilds.s3.eu-west-2.amazonaws.com/python"
S3_STORE="s3://ckir-debuilds/python/"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $BUILD_STORE/$PACKAGE_NAME)
if [ $HTTP_STATUS == "200" ]; then
    echo "$PACKAGE_NAME already exists at [$BUILD_STORE]. Build aborted"
    exit 0
fi

cd /Build
echo "Updating installed packages"
apt-get -qq update >/dev/null && apt-get -qq upgrade >/dev/null
echo "Installed packages updated"

cat <<EOF >>/etc/apt/sources.list
# Unstable
deb http://ftp.debian.org/debian unstable main contrib non-free
deb-src http://ftp.debian.org/debian unstable main contrib non-free

# Testing
deb http://ftp.debian.org/debian testing main contrib non-free
deb-src http://ftp.debian.org/debian testing main contrib non-free

# Experimental
deb http://ftp.debian.org/debian experimental main contrib non-free
deb-src http://ftp.debian.org/debian experimental main contrib non-free
EOF
echo "Updating Unstable/Testing/Experimental repos"
apt-get -qq update >/dev/null
echo "Unstable/Testing/Experimental updated"

echo "Installing build dependencies"
apt-get -qq install -y \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    liblzma-dev \
    tk-dev \
    libffi-dev >/dev/null
echo "Build dependencies installed"

echo "Downloading and extracting source"
wget -q https://www.python.org/ftp/python/$LATEST_VERSION/Python-$LATEST_VERSION.tgz
tar -xvf Python-$LATEST_VERSION.tgz
cd Python-$LATEST_VERSION/
echo "Source download completed"

./configure --enable-optimizations --with-ensurepip=install --prefix=/usr/local
make --silent -j$(nproc) >/dev/null
make altinstall DESTDIR="/Release/$INSTALL_DIR"
echo -e "\n\nBuild completed"

echo -e "\nPackaging started"
set -x
cd /Release/$INSTALL_DIR
mkdir DEBIAN
mkdir debian
touch debian/control

VERSION="$LATEST_VERSION"
VERSION="${VERSION#[vV]}"
VERSION_MAJOR="${VERSION%%\.*}"
VERSION_MINOR="${VERSION#*.}"
VERSION_MINOR="${VERSION_MINOR%.*}"
VERSION_PATCH="${VERSION##*.}"

cat <<EOF >./DEBIAN/control
Package: python$VERSION_MAJOR.$VERSION_MINOR
Version: $LATEST_VERSION
Architecture: i386
Maintainer: Never Mind <me@home.net>
Description: Python $LATEST_VERSION build from original source
EOF

DEPS=$(dpkg-shlibdeps -O ./usr/local/bin/python$VERSION_MAJOR.$VERSION_MINOR 2>/dev/null)
DEPS=${DEPS/shlibs:/""}
DEPS=${DEPS/=/": "}
echo $DEPS >>./DEBIAN/control
rm -Rf debian
cd ..
dpkg-deb --build --root-owner-group $INSTALL_DIR
echo "Packaging completed"

echo "Starting transfer"
aws configure set region $AWS_REGION
aws configure set aws_access_key_id $AWS_ACCESS_KEY
aws configure set aws_secret_access_key $AWS_SECRET_KEY
aws s3 cp $PACKAGE_NAME $S3_STORE
echo "Transfer completed"
