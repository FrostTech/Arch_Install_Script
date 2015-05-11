#Bootloader tweaks
#Grub
nano /etc/default/grub #Add "resume=[SWAP PARTITION]" to GRUB_CMDLINE_LINUX_DEFAULT
grub-mkconfig -o /boot/grub/grub.cfg #Regenerate the GRUB config
#Gummiboot
nano /boot/loader/entries/arch.conf #Add "resume=[SWAP PARTITION]" to options

#Account creation
useradd -m -G wheel -s /bin/bash [USERNAME] #Create a new account
usermod -aG audio,games,kvm,rfkill,users,uucp,video,wheel [USERNAME] #Add the new account to some groups
chfn [USERNAME] #Set extra info for the new account
passwd [USERNAME] #Set the password for the new account
EDITOR=nano visudo #Go to the part where it says "root ALL=(ALL) ALL" and add "[USERNAME] ALL=(ALL) ALL" on the next line


#Login to the new account
logout


#Install yaourt
wget https://aur.archlinux.org/packages/pa/package-query-git/package-query-git.tar.gz
tar -xzvf package-query-git.tar.gz 
cd package-query-git
makepkg -s
sudo pacman -U package-query-git-1.5.9.g4692c67-1-x86_64.pkg.tar.xz 
cd ..
rm -rf package-query-git*
wget https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
tar -xzvf yaourt.tar.gz 
cd yaourt
makepkg -s
sudo pacman -U yaourt-1.5-1-any.pkg.tar.xz 
cd ..
rm -rf yaourt*


#Install needed packages
sudo nano /etc/pacman.conf #Uncomment out all default repos
sudo pacman -Syyu #Download the latest repos and upgrade the system
sudo pacman -S xorg-server xorg xorg-xinit #Install X-Org
yaourt -S nvidia-dkms nvidia-hook #Install the Nvidia kernel module
sudo pacman -S nvidia-utils opencl-nvidia lib32-nvidia-libgl lib32-mesa-vdpau #Install Nvidia drivers
sudo reboot now #Reboot to load Nvidia drivers
sudo pacman -S ttf-dejavu ttf-liberation ttf-ubuntu-font-family #Install fonts
sudo pacman -S cinnamon nemo-fileroller nemo-preview nemo-seahorse networkmanager networkmanager-openconnect networkmanager-openvpn networkmanager-pptp networkmanager-vpnc #Install Cinnamon
sudo systemctl enable NetworkManager.service #Enable the network manager [1/2]
sudo systemctl enable NetworkManager-dispatcher.service #Enable the network manager [2/2]
sudo systemctl enable libvirtd.service #Enable libvirt
sudo systemctl enable clamd.service #Enable ClamAV [1/2]
sudo systemctl enable freshclamd.service #Enable ClamAV [2/2]
sudo pacman -S --needed android-tools audacity bc bleachbit checksec cheese chromium clamav conky cpupower eclipse empathy eog evince evolution filezilla freerdp gcc-multilib gedit gimp git gksudo gnome-calculator gnome-calendar gnome-disk-utility gnome-keyring gnome-screenshot gnome-sound-recorder gnome-system-log gnome-system-monitor gradm gst-libav gtkmm hexchat htop intellij-idea-community-edition jdk7-openjdk jdk8-openjdk jre7-openjdk jre7-openjdk-headless jre8-openjdk jre8-openjdk-headless keepass lib32-alsa-plugins lib32-readline libreoffice-fresh linux-grsec linux-headers mumble numix-themes parted pax-utils paxd paxtest perl-switch pigz proguard python python-pip python2-virtualenv qemu remmina rhythmbox schedtool seahorse squashfs-tools steam telepathy-gabble telepathy-idle telepathy-rakia telepathy-salut totem transmission-gtk virt-manager vlc wget wireshark-cli wireshark-gtk xfce4-terminal zip #Install official applications
sudo pip install doge speedtest-cli #Install python applications
sudo yaourt -S alsi android-sdk android-sdk-build-tools android-sdk-platform-tools android-studio archey arduino chromium-pepper-flash clamtk downgrade filebot hostsblock launch4j libtinfo minecraft 
networkmanager-l2tp numix-circle-icon-theme-git obs-studio-git pgl-git repo #Install AUR applications
sudo yaourt -S plex-media-server-plexpass #Install Plex
sudo systemctl enable plexmediaserver.service #Enable Plex


#Configure X-Org
sudo cp /etc/X11/xinit/xinitrc ~/.xinitrc
sudo chown [USERNAME] ~/.xinitrc
nano ~/.xinitrc #Remove the last five lines and add "exec cinnamon-session"
echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' > ~/.bash_profile #Start X-Org on login


#Network tweaks for games
sudo sysctl net.ipv4.tcp_ecn=1
sudo sysctl net.ipv4.tcp_sack=1 
sudo sysctl net.ipv4.tcp_dsack=1
sudo ip link set [MAIN NETWORK INTERFACE] qlen 25


#Kernel tweaks
nano /etc/mkinitcpio.conf #Add "lz4 lz4_compress kvm kvm_intel virtio-net virtio-blk virtio-scsi virtio-balloon" to modules and "shutdown resume nvidia" to hooks
mkinitcpio -p linux #Regenerate the kernel


#Misc
# - Add conky to startup applications in Cinnamon
# - Disable mouse acceleration: https://wiki.archlinux.org/index.php/Mouse_acceleration#Disabling_mouse_acceleration
# - Install VMWare: https://wiki.archlinux.org/index.php/VMware
# - Nemo - Scan file on right click with ClamAV: https://wiki.archlinux.org/index.php/Nemo#Clam_Scan
# - Yubikey support: https://www.yubico.com/faq/enable-u2f-linux/
# - Add polkit rules for libvirt: https://wiki.archlinux.org/index.php/Libvirt#Using_polkit
sudo echo 'SafeBrowsing Yes' > /etc/clamav/freshclam.conf #Enable an extra signature list to check files against
sudo archlinux-java set java-8-openjdk #Set default Java version to jre/jdk8
dconf load /org/cinnamon/desktop/keybindings/ < Keybinds.dconf #Load my keybinds
echo 'alias speedtest='speedtest-cli --share --server 2137'' > ~/.bash_profile #Add an alias for the best local Speedtest server


#Finishing up
sudo reboot now #Reboot the system
