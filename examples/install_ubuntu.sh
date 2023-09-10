#!/bin/bash

set -e

echo -e "Installing dependencies"
DEBIAN_FRONTEND=noninteractive sudo apt install -y \
	build-essential \
	clang \
	bison \
	flex \
	libreadline-dev \
	gawk \
	tcl-dev \
	libffi-dev \
	git \
	graphviz \
	xdot \
	pkg-config \
	python3 \
	libboost-system-dev \
	libboost-python-dev \
	libboost-filesystem-dev \
	zlib1g-dev \
	cmake \
	libboost-all-dev \
	libeigen3-dev \
	libftdi-dev \
	python3-dev \
	python3-pip

mkdir temp
pushd temp

echo -e "Installing icestorm"
mkdir icestorm
pushd icestorm
git init
git remote add origin https://github.com/YosysHQ/icestorm.git
git fetch --depth 1 origin d20a5e9001f46262bf0cef220f1a6943946e421d
git reset --hard FETCH_HEAD
make -j$(nproc)
sudo make install
popd

echo -e "Installing nextpnr"
git clone https://github.com/YosysHQ/nextpnr.git -b nextpnr-0.6 --depth 1
pushd nextpnr
cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local .
make -j$(nproc)
sudo make install
popd

echo -e "Installing yosys"
git clone https://github.com/YosysHQ/yosys.git -b yosys-0.33 --depth 1
pushd yosys
make -j$(nproc)
sudo make install
popd

echo -e "Installing gbdk-2020"
wget https://github.com/gbdk-2020/gbdk-2020/releases/download/4.2.0/gbdk-linux64.tar.gz
sudo tar -axvf gbdk-linux64.tar.gz -C /opt
popd

rm -rf temp

echo -e "Installing pyftdi"
pip3 install -r ../programmer/requirements.txt
