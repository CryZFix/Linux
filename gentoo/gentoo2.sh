#!/bin/bash

echo 'ACCEPT_LICENSE="*"' >> /etc/portage/make.conf

source /etc/profile
export PS1="(chroot) $PS1"

emerge-webrsync
### Eselect set desktop stable profile
#setprofile=$(eselect profile list|grep 'desktop (stable)'|awk -F "[" '{print $2}'|awk -F "]" '{print $1}')
#eselect profile set $setprofile
echo 'USE="elogind"' >> /etc/portage/make.conf
emerge -qvuDN @world
emerge cpuid2cpuflags sys-kernel/linux-firmware
echo "CPU_FLAGS_X86=$(cpuid2cpuflags | grep -oP ': \K.*')" | sed 's/=/="/;s/$/"/' >> /etc/portage/make.conf
echo 'INPUT_DEVICES="synaptics libinput"' >> /etc/portage/make.conf

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

#emerge -q sys-kernel/gentoo-sources sys-kernel/genkernel sys-fs/e2fsprogs sys-fs/btrfs-progs sys-fs/dosfstools dhcpcd app-admin/sudo sys-apps/pciutils
emerge -q sys-kernel/gentoo-kernel-bin sys-fs/e2fsprogs sys-fs/btrfs-progs sys-fs/dosfstools dhcpcd app-admin/sudo sys-apps/pciutils
rc-update add dhcpcd default
rc-update add elogind boot

### graphics driver
nvidia=$(lspci | grep -e VGA -e 3D | grep 'NVIDIA' 2> /dev/null || echo '')
amd=$(lspci | grep -e VGA -e 3D | grep 'AMD' 2> /dev/null || echo '')
intel=$(lspci | grep -e VGA -e 3D | grep 'Intel' 2> /dev/null || echo '')
if [[ -n "$nvidia" ]]; then
  echo 'VIDEO_CARDS="nouveau"' >> /etc/portage/make.conf
fi
if [[ -n "$amd" ]]; then
  echo 'VIDEO_CARDS="amdgpu radeon radeonsi"' >> /etc/portage/make.conf
fi
if [[ -n "$intel" ]]; then
  echo 'VIDEO_CARDS="intel"' >> /etc/portage/make.conf
fi

eselect kernel list
eselect kernel set 1
genkernel all

### Installing GRUB
emerge -q sys-boot/grub:2
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

emerge --autounmask-write y x11-base/xorg-drivers x11-base/xorg-server dev-vcs/git alacritty
etc-update
emerge USE="suid" x11-base/xorg-drivers x11-base/xorg-server dev-vcs/git alacritty

### Optional packages for dwm-flexepatcher
emerge x11-libs/libXft x11-libs/libXinerama

read -p "Enter username: " username
useradd -m -G wheel,audio,video $username
read -n 1 -s -r -p "Press any key to continue and type password for user: $username"
passwd $username
read -n 1 -s -r -p "Press any key to continue and type password for root user"
passwd
cd /home/$username
git clone https://github.com/bakkeby/dwm-flexipatch.git

exit
