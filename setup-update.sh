#! /bin/sh
#########################################################
# INTEL CONFIDENTIAL
# Copyright 2009-2018 Intel Corporation All Rights Reserved.
# 
# The source code contained or described herein and all documents related to the
# source code ("Material") are owned by Intel Corporation or its suppliers or
# licensors. Title to the Material remains with Intel Corporation or its
# suppliers and licensors. The Material may contain trade secrets and proprietary
# and confidential information of Intel Corporation and its suppliers and
# licensors, and is protected by worldwide copyright and trade secret laws and
# treaty provisions. No part of the Material may be used, copied, reproduced,
# modified, published, uploaded, posted, transmitted, distributed, or disclosed
# in any way without Intel's prior express written permission.
# 
# No license under any patent, copyright, trade secret or other intellectual
# property right is granted to or conferred upon you by disclosure or delivery
# of the Materials, either expressly, by implication, inducement, estoppel or
# otherwise. Any license under such intellectual property rights must be
# express and approved by Intel in writing.
# 
# Unless otherwise agreed by Intel in writing, you may not remove or alter this
# notice or any other notice embedded in Materials by Intel or Intel's suppliers
# or licensors in any way.
# 
#  version: NEV_SDK.L.0.4.0-00022
#########################################################
setup_dir=${PWD}

dpdk_arch=dpdk-16.07.2
dpdk_name=dpdk-16.07.2
dpdk_dir=/opt
#x86_64-native-linuxapp-gcc by default
dpdk_opt_target=15
dpdk_opt_exit=35
dpdk_url=http://fast.dpdk.org/rel/${dpdk_arch}.tar.xz

qemu_name=qemu-2.7.1
qemu_url=http://download.qemu-project.org/${qemu_name}.tar.xz
qemu_target_list=x86_64-softmmu

log "Install dependency package with yum"
yum -y install flex bison
yum -y install gcc gcc-c++
#yum -y install bridge-utils -y 
yum -y install gtk2-devel
#yum -y install virt-viewer
#yum -y install xorg-x11-xauth tigervnc –y
#yum -y install xorg-x11-font*

yum -y install boost-devel.x86_64
yum -y install openssl-devel.x86_64
yum -y install pcre-devel.x86_64
yum -y install zlib-devel.x86_64
yum -y install git cmake
yum -y install kernel-devel-$(uname -r)  # modified by xiaofen Liu

log()
{
	green='\033[0;32m'
	reset='\e[0m'
	echo -e "${green}$1${reset}"
}

log "Download DPDK"
#wget $dpdk_url
if [ $? -ne 0 ]; then
	log "DPDK package unavailable"
	exit 1
fi

log "Extract DPDK"
rm -rf ${dpdk_dir}/${dpdk_name}
mkdir -p ${dpdk_dir}/${dpdk_name}
tar -xmf ${dpdk_arch}.tar.xz -C ${dpdk_dir}/${dpdk_name} --strip 1
cd ${dpdk_dir}/${dpdk_name}

log "Build DPDK"
dpdk_config=${PWD}/config/common_linuxapp
sed -i '/CONFIG_RTE_KNI_KMOD=/s/=.*/=n/' $dpdk_config
sed -i '/CONFIG_RTE_LIBRTE_KNI=/s/=.*/=n/' $dpdk_config
cd tools
echo "$dpdk_opt_target

$dpdk_opt_exit" | ./dpdk-setup.sh 2>&1
rm $setup_dir/dpdk-*.tar.xz*

log "Show hugepages info"
grep -i huge /proc/meminfo

log "Mount hugepages"
rm -rf /mnt/huge-1048576kB/*
mkdir /mnt/huge-1048576kB > /dev/null
mount -t hugetlbfs nodev /mnt/huge-1048576kB

log "Download Qemu"
cd $setup_dir
wget  $qemu_url
if [ $? -ne 0 ]; then 
	log "Qemu package unavailable"
	exit 1
fi

log "Extract Qemu"
tar -xvmf ${qemu_name}.tar.xz > /dev/null
cd ${qemu_name}
log "Build Qemu"
rm -rf build
mkdir build && cd build
../configure --target-list=${qemu_target_list}
make
make install
rm $setup_dir/qemu*.tar.xz*


#Install Redis
pkg_url=http://download.redis.io/releases/redis-3.2.8.tar.gz
pkg_name=redis-3.2.8
log "Download $pkg_name"
cd $setup_dir
#wget $pkg_url
if [ $? -ne 0 ]; then
	log "$pkg_name package unavailable"
	exit 1
fi
log "Extract $pkg_name"
tar -xvmf $pkg_name.tar.gz > /dev/null
cd $setup_dir/$pkg_name
log "Build $pkg_name"
make MALLOC=libc && make install
if [ $? -ne 0 ]; then
	log "Compiled [ $pkg_name ] failed."
	exit 1
fi
# Copy configuration file redis-3.2.8/redis.conf to /etc/redis/redis.conf
test -d /etc/redis || mkdir /etc/redis
test -f /etc/redis/redis.conf && /bin/cp -a /etc/redis/redis.conf /etc/redis/redis.conf-backup
/bin/cp -a redis.conf /etc/redis/

rm -rf $setup_dir/$pkg_name*

#Install Nginx
pkg_url=http://nginx.org/download/nginx-1.10.3.tar.gz
pkg_name=nginx-1.10.3
log "Download $pkg_name"
cd $setup_dir
#wget $pkg_url
if [ $? -ne 0 ]; then
	log "$pkg_name package unavailable"
	exit 1
fi
log "Extract $pkg_name"
tar -xvmf $pkg_name.tar.gz > /dev/null
cd $setup_dir/$pkg_name
log "Build $pkg_name"
./configure --with-http_ssl_module && make install
if [ $? -ne 0 ]; then
	log "Compiled [ $pkg_name ] failed."
	exit 1
fi
# Link nginx executables to /usr/bin/
test -f /usr/bin/nginx && {
	/bin/cp -a /usr/bin/nginx /usr/bin/nginx-backup
	rm -rf /usr/bin/nginx
}
ln -s /usr/local/nginx/sbin/nginx /usr/bin/

# Link nginx configuration file to /etc/nginx/
test -d /etc/nginx || mkdir /etc/nginx
test -f /etc/nginx/nginx.conf && {
	/bin/cp -a /etc/nginx/nginx.conf /etc/nginx/nginx.conf-backup
	rm -rf /etc/nginx/nginx.conf
}
ln -s /usr/local/nginx/conf/nginx.conf /etc/nginx/

rm -rf $setup_dir/$pkg_name*

#Install libfcgi
pkg_url=ftp://ftp.linux.ro/gentoo/distfiles/fcgi-2.4.1-SNAP-0910052249.tar.gz
pkg_version=2.4.1-SNAP-0910052249
pkg_name=fcgi-2.4.1-SNAP-0910052249
log "Download $pkg_name"
cd $setup_dir
wget $pkg_url
if [ $? -ne 0 ]; then
	log "$pkg_name package unavailable"
	exit 1
fi
log "Extract $pkg_name"
tar -xvmf $pkg_name.tar.gz > /dev/null
cd $setup_dir/$pkg_name
log "Build $pkg_name"

sed -i 'N;24a#include <cstdio>' libfcgi/fcgio.cpp

./configure
make && make install
if [ $? -ne 0 ]; then
	log "Compiled [ $pkg_name ] failed."
	exit 1
fi
rm -rf $setup_dir/$pkg_name*

# Install Hiredis
pkg_url=https://github.com/redis/hiredis.git
pkg_version=v0.13.3
pkg_name=hiredis
log "Download $pkg_name"
cd $setup_dir
git clone -b $pkg_version $pkg_url
if [ $? -ne 0 ]; then
	log "$pkg_name package unavailable"
	exit 1
fi
cd $setup_dir/$pkg_name
log "Build $pkg_name"
make && make install
if [ $? -ne 0 ]; then
	log "Compiled [ $pkg_name ] failed."
	exit 1
fi
rm -rf $setup_dir/$pkg_name*

# Install Jsoncpp
pkg_url=https://github.com/open-source-parsers/jsoncpp.git
pkg_version=1.6.5
pkg_name=jsoncpp
log "Download $pkg_name"
cd $setup_dir
git clone -b $pkg_version $pkg_url
if [ $? -ne 0 ]; then
	log "$pkg_name package unavailable"
	exit 1
fi
cd $setup_dir/$pkg_name
log "Build $pkg_name"
cmake -H. -Bbuild && make -C build && make install -C build
if [ $? -ne 0 ]; then
	log "Compiled [ $pkg_name ] failed."
	exit 1
fi
rm -rf $setup_dir/$pkg_name*
cd $setup_dir

log "Done"
