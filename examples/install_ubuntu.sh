#!/bin/bash

set -e

echo -e "Installing dependency"
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
	mercurial \
	graphviz \
	xdot \
	pkg-config \
	python2 \
	python3 \
	libftdi-dev \
	python3-dev \
	python3-pip \
	libboost-all-dev \
	make \
	cmake \
	libeigen3-dev

mkdir temp
pushd temp

echo -e "Installing icestorm"
git clone https://github.com/YosysHQ/icestorm.git icestorm
pushd icestorm
git checkout 45f5e5f3889afb07907bab439cf071478ee5a2a5
make -j$(nproc)
sudo make install
popd

echo -e "Installing nextpnr"
git clone https://github.com/YosysHQ/nextpnr nextpnr
pushd nextpnr
git checkout nextpnr-0.5
cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local .
make -j$(nproc)
sudo make install
popd

echo -e "Installing yosys"
git clone https://github.com/YosysHQ/yosys.git yosys
pushd yosys
git checkout yosys-0.25
make -j$(nproc)
sudo make install
popd

echo -e "Installing gbdk-2020"
wget https://github.com/gbdk-2020/gbdk-2020/releases/download/4.1.1/gbdk-linux64.tar.gz
sudo tar -axvf gbdk-linux64.tar.gz -C /opt
export PATH=$PATH:/opt/gbdk/bin
echo "export PATH=\$PATH:/opt/gbdk/bin" >> ~/.bashrc

echo -e "Installing pyftdi"
popd
pip3 install -r ../programmer/requirements.txt

rm -rf temp

