#!/bin/bash
hostname=reichstag
username=junker
password=123456

# Hostname
echo $hostname > /etc/hostname

# Timezone
rm -f /etc/localtime
ln -svf /usr/share/zoneinfo/Europe/Samara /etc/localtime

# Create regular user
useradd -m -g users -G wheel -s /bin/bash $username
echo "$username:$password" | chpasswd

# Locale
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Create RAM loader
echo 'Создадим загрузочный RAM диск'
mkinitcpio -p linux-zen
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Config sudo
# allow users of group wheel to use sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL$/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL$/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
chmod 777 /home/$username/arch3.sh

# Uncomment multilib repo
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g' /etc/pacman.conf
pacman -Syy

# graphics driver
nvidia=$(lspci | grep -e VGA -e 3D | grep 'NVIDIA' 2> /dev/null || echo '')
amd=$(lspci | grep -e VGA -e 3D | grep 'AMD' 2> /dev/null || echo '')
intel=$(lspci | grep -e VGA -e 3D | grep 'Intel' 2> /dev/null || echo '')
if [[ -n "$nvidia" ]]; then
  pacman -S --noconfirm nvidia
fi

if [[ -n "$amd" ]]; then
  pacman -S --noconfirm xf86-video-amdgpu
fi

if [[ -n "$intel" ]]; then
  pacman -S --noconfirm xf86-video-intel
fi

if [[ -n "$nvidia" && -n "$intel" ]]; then
  pacman -S --noconfirm bumblebee
  gpasswd -a $username bumblebee
  systemctl enable bumblebeed
fi

# Enabe NM and sshd service
systemctl enable NetworkManager
systemctl enable sshd

# Downloading config for i3, polybar, etc
 # tar -czf config.tar.gz .config
chsh -s /bin/zsh junker
mkdir downloads
cd downloads
curl -OL https://raw.githubusercontent.com/CryZFix/Linux/main/archlinux/arch3.sh
rm /home/$username/.bashrc
sudo mv -f * /home/$username
sudo -u $username sh /home/$username/arch3.sh
sudo systemctl enable zramswap.service
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL$/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
wget https://github.com/CryZFix/Linux/raw/main/archlinux/attach/config.tar
sudo rm -rf /home/$username/.config/*
sudo tar -xvf config.tar -C /home/$username
sudo chown junker:user /home/$username/.*

# Adding autologin without DE
sudo echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin" "$username" '- $TERM' > autologin.conf
sudo mkdir /etc/systemd/system/getty@tty1.service.d/
sudo mv -f autologin.conf /etc/systemd/system/getty@tty1.service.d/autologin.conf

cd ..
rm -rf downloads
echo 'Install is complete, rebooting...'
exit
