source settings
# Error exit straight away
# set -e
echo "Setting Passwords"
echo "root:$rootpass" | chpasswd
# <enter new root password>
# <re-enter new root password>

useradd -G sudo -m -s /bin/bash "$username"
echo "$username:$userpass" | chpasswd
# <enter new user password>
# <re-enter new user password>

echo "$image_hostname" > /etc/hostname
echo "127.0.0.1    localhost.localdomain localhost" > /etc/hosts
echo "127.0.0.1    $image_hostname" >> /etc/hosts
mkdir /etc/network
mkdir /etc/network/interfaces.d
echo "auto eth0" > /etc/network/interfaces.d/eth0
echo "iface eth0 inet static
        address $image_ip
        netmask $image_netmask
        gateway $image_gateway
        dns-nameservers $image_dns
" >> /etc/network/interfaces.d/eth0
echo "nameserver $image_dns" > /etc/resolv.conf

apt update
apt-get -y upgrade
apt-get -y install vim ifupdown net-tools sudo ssh iptables openvpn nano unzip

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

sudo apt-get -y install iptables-persistent

systemctl enable openvpn@$vpnfile

exit
