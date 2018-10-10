
# Based off https://forum.armbian.com/topic/6850-document-about-compiling-a-kernel-and-rootfs-for-the-firefly-boards/
# Designed to build an Ubuntu 16.04 with tun for VPN

# Error exit straight away
#set -e 

# Load in settings
source settings

echo "Building image for $image_hostname"

sudo apt-get -y install gcc python bc git gcc-arm-linux-gnueabihf gcc-aarch64-linux-gnu device-tree-compiler lzop libncurses5-dev libssl1.0.0 libssl-dev qemu qemu-user-static binfmt-support debootstrap swig libpython-dev mtools pv wget make gdisk

mkdir firefly_build
cd firefly_build

# Use the stable releases - 4.4 kernel being updated, MALI GPU broken
#git clone -b release-4.4 https://github.com/FireflyTeam/kernel.git
#git clone -b debian https://github.com/FireflyTeam/build.git
#git clone -b master https://github.com/FireflyTeam/rkbin.git
#git clone -b release https://github.com/FireflyTeam/u-boot.git

# Old releases still working
# U-Boot
git clone -b roc-rk3328-cc https://github.com/FireflyTeam/u-boot
# Kernel
git clone -b roc-rk3328-cc https://github.com/FireflyTeam/kernel --depth=1
# Build
git clone -b debian https://github.com/FireflyTeam/build
# Rkbin
git clone -b master https://github.com/FireflyTeam/rkbin

cd kernel

#-------
# Load Config from "arch/arm64/configs/fireflyrk3328_linux_defconfig"
#
# Device Drivers -->
#   Network Device Support --->
#     Universal TUN/TAP device driver support <Mark with an asterisk(*)>
#
# Networking Support --->
#   Networking Options --->
#     Network packet filtering framework (Netfilter) --->
#       Core Netfilter Configuration --->
#         <Mark all options with an asterisk (*)>
#
# Networking Support --->
#   Networking Options --->
#     Network packet filtering framework (Netfilter) --->
#      IP: Net Filter configurations -->
#        <Mark all options with an asterisk (*)>
#
# Save Config to "arch/arm64/configs/fireflyrk3328_linux_defconfig"
#-------

rm .config
cp ../../fireflyrk3328_linux_defconfig-4.4.114 arch/arm64/configs/fireflyrk3328_linux_defconfig
cp ../../fireflyrk3328_linux_defconfig-4.4.114 .config

cd ..
./build/mk-kernel.sh roc-rk3328-cc

./build/mk-uboot.sh roc-rk3328-cc

mkdir ubuntu_core
install -d ./ubuntu_core/{linux,rootfs,archives/{ubuntu-base,debs,hwpacks},images,scripts}
cd ubuntu_core
wget -P archives/ubuntu-base -c http://cdimage.ubuntu.com/ubuntu-base/releases/16.04.4/release/ubuntu-base-16.04.4-base-arm64.tar.gz

 
# 4Gb should be enough, resize to card size kills the boot atm
dd if=/dev/zero of=images/rootfs.img bs=1M count=0 seek=${image_size}
sudo mkfs.ext4 -F -L ROOTFS images/rootfs.img
# <enter user password>
rm -rf rootfs && install -d rootfs
sudo mount -o loop images/rootfs.img rootfs
sudo rm -rf rootfs/lost+found
sudo tar -xzf archives/ubuntu-base/ubuntu-base-16.04.4-base-arm64.tar.gz -C rootfs/
sudo cp -a /usr/bin/qemu-aarch64-static rootfs/usr/bin/

sudo mkdir rootfs/etc/openvpn
sudo cp ../../$vpnfile rootfs/etc/openvpn -v

# sudo echo gets permisison denied for some reason
echo "$vpnname
$vpnpass" > login.conf
sudo cp login.conf rootfs/etc/openvpn/login.conf -v

pwd

sudo cp ../../settings rootfs/ -v
sudo cp ../../config.sh rootfs/ -v
sudo cp ../../rc.local rootfs/etc/ -v
sudo cp ../../rootfs_resize.sh rootfs/sbin/ -v
#sudo chroot rootfs/
sudo chroot rootfs /bin/bash -c "/config.sh"

sudo sync
# <enter user password>
sudo umount rootfs/


cd ..

build/mk-image.sh -c rk3328 -t system -r ubuntu_core/images/rootfs.img
build/flash_tool.sh -c rk3328 -d ../ubuntu_16.04.4_roc-rk3328-cc_arch64_$(date +%Y%m%d).img -p system -i out/system.img

