#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

LATEST_VERSION=$(curl -sL https://nodejs.org/download/release/latest/ | html2text | grep linux-x64.tar.gz | grep -oP 'node-v\K[0-9]+\.[0-9]+\.[0-9]+' | sed 's/-.*//')
echo "NodeJS latest available version found is: $LATEST_VERSION"
INSTALL_DIR="nodejs_$LATEST_VERSION-1_i386"
PACKAGE_NAME="$INSTALL_DIR.deb"
BUILD_STORE="https://ckir-debuilds.s3.eu-west-2.amazonaws.com/nodejs"
S3_STORE="s3://ckir-debuilds/nodejs/"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $BUILD_STORE/$PACKAGE_NAME)
if [ $HTTP_STATUS == "200" ]; then
    echo "$PACKAGE_NAME already exists at [$BUILD_STORE]. Build aborted"
    exit 0
fi

cd /Build
echo "Updating installed packages"
wget http://http.us.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20230311_all.deb
dpkg -r --force-depends ca-certificates
dpkg -i ca-certificates_20230311_all.deb
apt-get -qq update >/dev/null && apt-get -y -qq upgrade >/dev/null
echo "Installed packages updated"

echo "Installing build dependencies"
apt-get -y -qq install python3 g++ make python3-pip ninja-build
apt-get -y -qq build-dep nodejs > /dev/null
echo "Build dependencies installed"

echo "Downloading and extracting source"
wget -q https://nodejs.org/dist/v$LATEST_VERSION/node-v$LATEST_VERSION.tar.gz
tar -xzf node-v$LATEST_VERSION.tar.gz
echo "Source download completed"

cd node-v$LATEST_VERSION
./configure --help
./configure --ninja --shared-zlib
for f in $(find deps/openssl -type f -name '*.S'); do
    echo $f
    sed -i "s/%ifdef/#ifdef/" "$f"
    sed -i "s/%endif/#endif/" "$f"
done

make --silent -j$(nproc) > /dev/null
make install DESTDIR=/Release/$INSTALL_DIR
echo -e "\n\nBuild completed"

echo -e "\nPackaging started"
cd /Release/$INSTALL_DIR
mkdir DEBIAN
mkdir debian
touch debian/control

cat <<EOF >./DEBIAN/control
Package: nodejs$MAJOR
Version: $LATEST_VERSION
Architecture: i386
Maintainer: Never Mind <me@home.net>
Description: NodeJS $LATEST_VERSION build from original source
EOF

DEPS=$(dpkg-shlibdeps -O ./usr/local/bin/node 2>/dev/null)
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
