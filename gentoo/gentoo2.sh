#!/bin/bash

echo 'ACCEPT_LICENSE="*"' >> /etc/portage/make.conf

source /etc/profile
export PS1="(chroot) $PS1"

emerge-webrsync

eselect profile list
read -p "Enter number your choice profile: " setprofile
eselect profile set $setprofile

emerge -qvuDN @world
emerge cpuid2cpuflags
echo "CPU_FLAGS_X86=$(cpuid2cpuflags | grep -oP ': \K.*')" | sed 's/=/="/;s/$/"/' >> /etc/portage/make.conf

echo "Europe/Samara" > /etc/timezone
emerge --config sys-libs/timezone-data

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo 'ru_RU.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
eselect locale list
eselect locale set 4

sed -i 's/CONSOLEFONT="default8x16"/CONSOLEFONT="cyr-sun16"/' /etc/conf.d/consolefont
env-update && source /etc/profile
export PS1="(chroot) $PS1"

emerge -q sys-kernel/gentoo-sources sys-kernel/genkernel sys-fs/e2fsprogs sys-fs/btrfs-progs sys-fs/dosfstools dhcpcd
rc-update add dhcpcd default
echo '/dev/sda1         /boot       ext2        defaults                0 2' > /etc/fstab
eselect kernel list
eselect kernel set 1

echo 'Kernel config Manual or use genkernel?'
read -p "1 - Manual, 2 - Genkernel: " node_set
if [[ $node_set == 1 ]]; then
cd /usr/src/linux
make menuconfig
make -j9 bzImage
make -j9 modules
make install
make INSTALL_MOD_STRIP=1 modules_install
elif [[ $node_set == 2 ]]; then
genkernel all
fi

echo '/dev/sda2         none        swap        sw                      0 0' >> /etc/fstab
echo '/dev/sda3         /           ext4        noatime                 0 1' >> /etc/fstab

read -p "Enter name your PC: " sethostname
echo hostname="$sethostname" > /etc/conf.d/hostname

read -p "Enter username: " username
useradd -m -G wheel,audio,video $username
read -n 1 -s -r -p "Press any key to continue and type password for user: $username"
passwd $username
read -n 1 -s -r -p "Press any key to continue and type password for root user"
passwd

emerge -q sys-boot/grub:2

echo 'Grub for BIOS or UEFI?'
read -p "1 - BIOS, 2 - UEFI: " node_set
if [[ $node_set == 1 ]]; then
grub-install /dev/sda
elif [[ $node_set == 2 ]]; then
grub-install --target=x86_64-efi --efi-directory=/boot
fi

grub-mkconfig -o /boot/grub/grub.cfg

exit
