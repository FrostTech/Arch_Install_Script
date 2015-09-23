#Color codes from https://wiki.archlinux.org/index.php/Color_Bash_Prompt
coloroff='\e[0m'
black='\e[0;30m'
blue='\e[0;34m'
cyan='\e[0;36m'
green='\e[0;32m'
purple='\e[0;35m'
red='\e[0;31m'
white='\e[0;37m'
yellow='\e[0;33m'
infoColor=${green}
questionColor=${red}
outputColor=${yellow}

#Intro
echo -e ${infoColor}"Welcome to the Spot Communication's Arch Linux installer and configurator"
echo -e ${infoColor}"This is the pre-install script meant to be run from a live media"
echo -e ${infoColor}"This script has yet to be throughly tested, stuff might go very, very wrong"
echo -e ${infoColor}"Ctrl+C within 10 seconds if you do not want to end up troubleshooting your system or have to attempt to recover lost files"
sleep 10

#Connect to the network
echo -e ${infoColor}"START OF NETWORK CONFIG"
echo -e ${questionColor}"Do you plan on using Wi-Fi for this install? Answering no will auto connect on all ethernet interfaces"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) wifi-menu; break;;
        No ) systemctl start dhcpcd.service; break;;
    esac
done
echo -e ${infoColor}"END OF NETWORK CONFIG"
sleep 3

#Partition the drive
echo -e ${infoColor}"START OF PARTITIONING"
lsblk
echo -e ${questionColor}"What drive do you want to install Arch onto? (/dev/sdX)"
read strInstallDrive
echo -e ${questionColor}"Where do you want your /boot partition to end? (Recommend Size: 1GiB)"
read strPartitionSizeBoot
echo -e ${questionColor}"Where do you want your / partition to end? (Recommend Size: 32GiB)"
read strPartitionSizeSystem
echo -e ${questionColor}"Where do you want your swap partition to end? (Recommend Size: Amount of RAM installed)"
read strPartitionSizeSwap
echo -e ${questionColor}"Where do you want your /home partition to end? (Recommend Size: 100%)"
read strPartitionSizeHome
echo -e ${questionColor}"Do you have a (U)EFI system or a plain BIOS system?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) blEFI=true; break;;
		No ) blEFI=false; break;;
	esac
done
echo -e ${outputColor}
parted ${strInstallDrive} rm 1
parted ${strInstallDrive} rm 2
parted ${strInstallDrive} rm 3
parted ${strInstallDrive} rm 4
parted ${strInstallDrive} rm 5
parted ${strInstallDrive} rm 6
dd if=/dev/zero of=${strInstallDrive} bs=512 count=10
if [ ${blEFI} == true ]
	then
		parted ${strInstallDrive} mklabel gpt
		parted ${strInstallDrive} mkpart primary fat32 1MiB ${strPartitionSizeBoot}
	else
		parted ${strInstallDrive} mklabel msdos
		parted ${strInstallDrive} mkpart primary ext4 1MiB ${strPartitionSizeBoot}
fi
parted ${strInstallDrive} set 1 boot on
parted ${strInstallDrive} mkpart primary ext4 ${strPartitionSizeBoot} ${strPartitionSizeSystem}
parted ${strInstallDrive} mkpart primary linux-swap ${strPartitionSizeSystem} ${strPartitionSizeSwap}
parted ${strInstallDrive} mkpart primary ext4 ${strPartitionSizeSwap} ${strPartitionSizeHome}
echo -e ${infoColor}"END OF PARTITIONING"
sleep 3

#Format the partitions
echo -e ${infoColor}"START OF FORMATTING"
echo -e ${outputColor}
if [ ${blEFI} == true ]
	then
		mkfs.vfat -F32 ${strInstallDrive}1
	else
		mkfs.ext4 {$strInstallDrive}1
fi
mkfs.ext4 ${strInstallDrive}2
mkswap ${strInstallDrive}3
swapon ${strInstallDrive}3
mkfs.ext4 ${strInstallDrive}4
sync

#Mount the partitions
mount ${strInstallDrive}2 /mnt
cd /mnt
rm -rf *
mkdir -p /mnt/boot
mkdir -p /mnt/home
mount ${strInstallDrive}1 /mnt/boot
cd /mnt/boot
rm -rf *
mount ${strInstallDrive}4 /mnt/home
cd /mnt/home
rm -rf *
cd ~
echo -e ${infoColor}"END OF FORMATTING"
sleep 3

#Update local mirrors
echo -e ${infoColor}"UPDATING LOCAL MIRRORS"
echo -e ${outputColor}
pacman -Sy reflector
reflector --verbose --country 'United States' -l 200 -p http -p https --sort rate --save /etc/pacman.d/mirrorlist
sleep 3

#Install the base system
echo -e ${infoColor}"INSTALLING THE BASE SYSTEM"
echo -e ${outputColor}
pacstrap -i /mnt base base-devel wget iw wpa_supplicant reflector
sleep 3


#Generate an fstab
echo -e ${infoColor}"GENERATING FSTAB"
genfstab -U -p /mnt >> /mnt/etc/fstab

#Set locale
echo -e ${infoColor}"START OF SETTING LOCALE"
echo -e ${questionColor}"What language would you like to use? (en_US.UTF-8)"
read strLanguage
echo -e ${outputColor}
arch-chroot /mnt /bin/bash -c "sed -i 's/#${strLanguage}/${strLanguage}/' /etc/locale.gen"
arch-chroot /mnt locale-gen
arch-chroot /mnt /bin/bash -c "echo LANG=${strLanguage} > /etc/locale.conf"
echo -e ${infoColor}"END OF SETTING LOCALE"
sleep 3

#Set timezone
echo -e ${infoColor}"START OF SETTING TIMEZONE"
echo -e ${questionColor}"What timezone are you in? (America/New_York)"
read strTimezone
echo -e ${outputColor}
arch-chroot /mnt /bin/bash -c "ln -s /usr/share/zoneinfo/${strTimezone} /etc/localtime"
arch-chroot /mnt hwclock --systohc --utc
echo -e ${infoColor}"END OF SETTING TIMEZONE"
sleep 3

#Set hostname
echo -e ${infoColor}"START OF SETTING HOSTNAME"
echo -e ${questionColor}"What would you like your hostname to be?"
read strHostname
arch-chroot /mnt /bin/bash -c "echo ${strHostname} > /etc/hostname"
arch-chroot /mnt /bin/bash -c "sed -i 's/localhost /localhost $strHostname/' /etc/hosts"
echo -e ${infoColor}"END OF SETTING HOSTNAME"
sleep 3

#Install the bootloader
echo -e ${infoColor}"START OF BOOTLOADER INSTALLATION"
echo -e ${outputColor}
if [ ${blEFI} == true ]
        then
		arch-chroot /mnt pacman -S dosfstools
		arch-chroot /mnt bootctl --path=/boot install
		arch-chroot /mnt /bin/bash -c 'echo "title Arch Linux" >> /boot/loader/entries/arch.conf\'
		arch-chroot /mnt /bin/bash -c 'echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf\'
		arch-chroot /mnt /bin/bash -c 'echo "initrc /initramfs-linux.img" >> /boot/loader/entries/arch.conf\'
		arch-chroot /mnt /bin/bash -c $'echo "options root=${strInstallDrive}1 rw resume=${strInstallDrive}3" >> /boot/loader/entries/arch.conf\'
		arch-chroot /mnt /bin/bash -c 'echo "timeout 0" > /boot/loader/loader.conf\' #There is only 1 > because the file is created on install, and were overwriting it
		arch-chroot /mnt /bin/bash -c 'echo "default arch" >> /boot/loader/loader.conf\'
        else
		arch-chroot /mnt pacman -S grub os-prober
		arch-chroot /mnt grub-install --target=i386-pc --recheck ${strInstallDrive}
		arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
fi
echo -e ${infoColor}"END OF BOOTLOADER INSTALLATION"
sleep 3

#Set root password
echo -e ${infoColor}"SETTING ROOT PASSWORD"
echo -e ${questionColor}"Please set a password for the root account"
echo -e ${outputColor}
arch-chroot /mnt passwd
sleep 3

#Create a user account
echo -e ${infoColor}"START OF USER ACCOUNT CREATION"
echo -e ${questionColor}"What would you like your username to be? Must be all lowercase."
read strUsername
echo -e ${outputColor}
arch-chroot /mnt useradd -m -G wheel -s /bin/bash ${strUsername}
arch-chroot /mnt usermod -aG audio,games,rfkill,users,uucp,video,wheel ${strUsername}
arch-chroot /mnt chfn ${strUsername}
echo -e ${questionColor}"Please add your username to the sudoers file after root ALL=(ALL) ALL"
sleep 5
arch-chroot /mnt /bin/bash -c "EDITOR=nano visudo"
echo -e ${questionColor}"Please set a password for your account"
echo -e ${outputColor}
arch-chroot /mnt passwd ${strUsername}
echo -e ${infoColor}"END OF USER ACCOUNT CREATION"
sleep 3

#Post-Install Script
echo -e ${infoColor}"INSTALLING POST INSTALL SCRIPT"
echo -e ${outputColor}
wget https://raw.githubusercontent.com/SpotComms/Arch_Install_Commands/master/Post-Install.sh
cp Post-Install.sh /mnt/home/${strUsername}/
echo -e ${infoColor}"INSTALLED POST INSTALL SCRIPT"
sleep 3

#Finish up
echo -e ${infoColor}"FINISHING UP"
umount -R /mnt
echo -e ${infoColor}"After reboot please login and run 'sh Post-Install.sh'"
sleep 10
echo -e ${coloroff}
reboot now
