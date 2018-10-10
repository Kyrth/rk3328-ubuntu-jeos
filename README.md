# rk3328-ubuntu-jeos

Build scripts for Ubuntu 14.04-LTS on Libre Computer Renegade (RK3328)

Designed to build ultra lightweight OS, currently with OpenVPN client scripts.

OpenVPN will be split out as an option once the build system works

# Usage

Edit settings file to set the default network/vpn info
Create client.conf (or get it from OpenVPN Server)

./build-os.sh will build the image

Write to SDcard, and boot. 

# Note

Renegade HDMI output will not work right unless monitor/tv + cable is connected BEFORE booting!

