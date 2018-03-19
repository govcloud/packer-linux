#!/bin/bash -eux

if [[ $AZURE  =~ true || $AZURE =~ 1 || $AZURE =~ yes ]]; then

echo "==> Applying Azure configuration"

# Force hyperv drivers (maybe only needed when unattended installing under qemu)
# Do this early on so that any kernel updated via yum is built w/ hv drivers
echo 'add_drivers+="hv_vmbus hv_netvsc hv_storvsc"' >> /etc/dracut.conf
echo "kickstart_post: begin rebuilding kernel"
dracut -f -v
echo "kickstart_post: finished rebuilding kernel"

# subscribe
# subscription-manager register --username='<USERNAME>' --password='<PASSWORD>' --auto-attach --force
# yum update -y

# Disable the root account
# usermod root -p '!!'

# Set OL repos
curl -so /etc/yum.repos.d/CentOS-Base.repo https://raw.githubusercontent.com/szarkos/AzureBuildCentOS/master/config/azure/CentOS-Base-7.repo
curl -so /etc/yum.repos.d/OpenLogic.repo https://raw.githubusercontent.com/szarkos/AzureBuildCentOS/master/config/azure/OpenLogic.repo

# Import CentOS and OpenLogic public keys
curl -so /etc/pki/rpm-gpg/OpenLogic-GPG-KEY https://raw.githubusercontent.com/szarkos/AzureBuildCentOS/master/config/OpenLogic-GPG-KEY
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
rpm --import /etc/pki/rpm-gpg/OpenLogic-GPG-KEY

# Modify yum
echo "http_caching=packages" >> /etc/yum.conf

# Configure swap in WALinuxAgent
# sed -i 's/^\(ResourceDisk\.EnableSwap\)=[Nn]$/\1=y/g' /etc/waagent.conf
# sed -i 's/^\(ResourceDisk\.SwapSizeMB\)=[0-9]*$/\1=2048/g' /etc/waagent.conf

# Set the kernel cmdline
sed -i 's/^\(GRUB_CMDLINE_LINUX\)=".*"$/\1="console=tty1 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 rootdelay=300 net.ifnames=0"/g' /etc/default/grub

# Rebuild grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg

# Enable SSH keepalive
sed -i 's/^#\(ClientAliveInterval\).*$/\1 180/g' /etc/ssh/sshd_config

# Configure network
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
USERCTL=no
PEERDNS=yes
IPV6INIT=no
NM_CONTROLLED=no
EOF

cat << EOF > /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=localhost.localdomain
EOF

# Deploy new configuration
cat <<EOF > /etc/pam.d/system-auth-ac

auth        required      pam_env.so
auth        sufficient    pam_fprintd.so
auth        sufficient    pam_unix.so nullok try_first_pass
auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
auth        required      pam_deny.so

account     required      pam_unix.so
account     sufficient    pam_localuser.so
account     sufficient    pam_succeed_if.so uid < 1000 quiet
account     required      pam_permit.so

password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
EOF

# Disable persistent net rules
touch /etc/udev/rules.d/75-persistent-net-generator.rules
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules /etc/udev/rules.d/70-persistent-net.rules 2>/dev/null

# Disable NetworkManager handling of the SRIOV interfaces
curl -so /etc/udev/rules.d/68-azure-sriov-nm-unmanaged.rules https://raw.githubusercontent.com/LIS/lis-next/master/rpmbuild/rh7/SOURCES/68-azure-sriov-nm-unmanaged.rules

# Disable some unneeded services by default (administrators can re-enable if desired)
systemctl disable abrtd

# Deprovision and prepare for Azure
/usr/sbin/waagent -force -deprovision

# Clear bash history
export HISTSIZE=0
rm -f /root/.bash_history

# Workaround old agent bug
rm -f /etc/resolv.conf 2>/dev/null

fi
