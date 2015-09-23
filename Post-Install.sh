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
echo -e ${infoColor}"This is the post-install script meant to be run after doing a base install"
echo -e ${infoColor}"This script has yet to be throughly tested, stuff might go very, very wrong"
echo -e ${infoColor}"Ctrl+C within 10 seconds if you do not want to end up troubleshooting your system or have to attempt to recover lost files"
sleep 10

#Connect to the network
echo -e ${infoColor}"START OF NETWORK CONFIG"
echo -e ${questionColor}"Do you plan on using Wi-Fi for this install? Answering no will auto connect on all ethernet interfaces"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) sudo wifi-menu; break;;
        No ) sudo systemctl start dhcpcd.service; break;;
    esac
done
echo -e ${infoColor}"END OF NETWORK CONFIG"
sleep 15

#Configure pacman
echo -e ${infoColor}"START OF PACMAN CONFIGURATION"
sudo sed -i 's/#\[testing\]/\[testing\]/' /etc/pacman.conf
sudo sed -i 's/#\[community-testing\]/\[community-testing\]/' /etc/pacman.conf
sudo sed -i 's/#\[multilib-testing\]/\[multilib-testing\]/' /etc/pacman.conf
sudo sed -i 's/#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sudo sed -i 's/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/' /etc/pacman.conf
echo -e ${outputColor}
sudo reflector --verbose --country 'United States' -l 200 -p http -p https --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syyu
echo -e ${infoColor}"END OF PACMAN CONFIGURATION"
sleep 3

#Configure makepkg
echo -e ${infoColor}"START OF MAKEPKG CONFIGURATION"
sudo sed -i 's/CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fstack-protector-strong -fstack-check"/CFLAGS="-march=native -mtune=native -O3 -pipe -fstack-protector-strong -fstack-check --param=ssp-buffer-size=4"/' /etc/makepkg.conf
sudo sed -i 's/CXXFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fstack-protector-strong -fstack-check"/CXXFLAGS="${CFLAGS}"/' /etc/makepkg.conf
echo -e ${questionColor}"How many threads do you have?"
read strAmtThreads
sudo sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j${strAmtThreads}\"/" /etc/makepkg.conf
#TODO: Change packager name here
sudo sed -i 's/(xz -c -z -)/(xz -T 0 -c -z -)/' /etc/makepkg.conf
echo -e ${infoColor}"END OF MAKEPKG CONFIGURATION"
sleep 3

#Install and configure yaourt
echo -e ${infoColor}"START OF YAOURT INSTALLATION"
echo -e ${outputColor}
cd /tmp
wget https://aur.archlinux.org/cgit/aur.git/snapshot/package-query-git.tar.gz
tar -xzvf package-query-git.tar.gz
cd package-query-git
makepkg -s
sudo pacman -U package-query-git-*.tar.xz
cd ..
wget https://aur.archlinux.org/cgit/aur.git/snapshot/yaourt-git.tar.gz
tar -xzvf yaourt-git.tar.gz
cd yaourt-git
makepkg -s
sudo pacman -U yaourt-git-*.tar.xz
cd ~
echo -e ${infoColor}"END OF YAOURT INSTALLATION"
sleep 3

#Frameworks
echo -e ${infoColor}"START OF FRAMEWORKS INSTALLATION"
echo -e ${outputColor}
sudo pacman -S --needed gcc-multilib jdk7-openjdk jdk8-openjdk jre7-openjdk jre8-openjdk python python-pip python2-virtualenv
sudo archlinux-java set java-8-openjdk
echo -e ${infoColor}"END OF FRAMEWORKS INSTALLATION"
sleep 3

#Install and configure X-org
echo -e ${infoColor}"START OF X-ORG INSTALLATION"
echo -e ${outputColor}
sudo pacman -S --needed xorg-server xorg xorg-xinit libvdpau-va-gl libvdpau lib32-libvdpau lib32-mesa-vdpau libva-vdpau-driver mesa-vdpau libva-intel-driver libgl lib32-libgl
wget https://raw.githubusercontent.com/SpotComms/Arch_Install_Commands/master/home/.xinitrc
wget https://raw.githubusercontent.com/SpotComms/Arch_Install_Commands/master/home/.Xresources
echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' > ~/.bash_profile
echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' > ~/.zprofile
sudo /bin/bash -c $'echo \'Section "InputClass"\' >> /etc/X11/xorg.conf.d/50-mouse-acceleration.conf'
sudo /bin/bash -c $'echo \'	Identifier "My Mouse"\' >> /etc/X11/xorg.conf.d/50-mouse-acceleration.conf'
sudo /bin/bash -c $'echo \'	MatchIsPointer "yes"\' >> /etc/X11/xorg.conf.d/50-mouse-acceleration.conf'
sudo /bin/bash -c $'echo \'	Option "AccelerationProfile" "-1"\' >> /etc/X11/xorg.conf.d/50-mouse-acceleration.conf'
sudo /bin/bash -c $'echo \'	Option "AccelerationScheme" "none"\' >> /etc/X11/xorg.conf.d/50-mouse-acceleration.conf'
sudo /bin/bash -c $'echo \'	Option "AccelSpeed" "-1"\' >> /etc/X11/xorg.conf.d/50-mouse-acceleration.conf'
sudo /bin/bash -c $'echo \'EndSection\' >> /etc/X11/xorg.conf.d/50-mouse-acceleration.conf'
echo -e ${questionColor}"Do you need NVIDIA Optimus drivers? (Bumblebee)" 
select yn in "Yes" "No"; do
        case $yn in
                Yes ) 
                	echo -e ${outputColor};
			sudo pacman -S --needed bumblebeed primus lib32-primus virtualgl lib32-virtualgl bbswitch mesa lib32-mesa mesa-libgl lib32-mesa-libgl mesa-vdpau lib32-mesa-vdpau xf86-video-intel xf86-video-nv lib32-nvidia-utils nvidia-utils lib32-opencl-nvidia opencl-nvidia nvidia;
			sudo systemctl enable bumblebeed.service;
			sudo gpasswd -a $USER bumblebee;
			sudo sed -i 's/MODULES="/MODULES="i915 bbswitch /' /etc/mkinitcpio.conf;
			sudo mkinitcpio -p linux;
			break;;
                No ) break;;
        esac
done
echo -e ${questionColor}"Do you need NVIDIA drivers?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) echo -e ${outputColor}; sudo pacman -S --needed nvidia-utils opencl-nvidia lib32-nvidia-libgl lib32-mesa-vdpau nvidia; break;;
		No ) break;;
	esac
done
#TODO Add support for older NVIDIA cards, AMD cards and AMD cards with Intel (PRIME)
echo -e ${infoColor}"END OF X-ORG CONFIGURATION"
sleep 3

#Cinnamon
echo -e ${infoColor}"START OF CINNAMON INSTALLATION"
echo -e ${outputColor}
sudo pacman -S --needed cinnamon nemo-fileroller nemo-preview networkmanager networkmanager-openconnect networkmanager-openvpn networkmanager-pptp networkmanager-vpnc xfce4-terminal
sudo systemctl enable NetworkManager.service
sudo systemctl enable NetworkManager-dispatcher.service
echo -e ${infoColor}"END OF CINNAMON INSTALLATION"
sleep 3


#Applications
echo -e ${infoColor}"START OF APPLICATIONS INSTALLATION"
echo -e ${questionColor}"Do you want applications from the basics group??"
select yn in "Yes" "No"; do
        case $yn in
                Yes )
                	echo -e ${outputColor};
			sudo pacman -S --needed bleachbit cdrkit chromium cpupower eog evince evolution gedit gimp git gksu gnome-calculator gnome-disk-utility gnome-keyring gnome-screenshot gnome-system-monitor gst-libav gst-plugins-bad gst-plugins-base gst-plugins-good gst-plugins-ugly hdparm htop libreoffice-fresh lib32-alsa-plugins linux-headers mumble ntfs-3g openssh parted pigz pulseaudio-alsa pulseaudio-equalizer pulseaudio-gconf redshift seahorse totem transmission-gtk unrar wine wine-mono wine_gecko winetricks wget zip zsh acpi acpi_call ethtool smartmontools linux-tools intel-ucode gparted btrfs-progs dosfstools e2fsprogs exfat-utils f2fs-tools jfsutils ntfs-3g reiserfsprogs xfsprogs mtools gpart nilfs-utils pigz pixz lbzip2 bind-tools gperf lm_sensors;
			yaourt -S alsi chromium-pepper-flash downgrade nano-syntax-highlighting-git notepadqq-git oh-my-zsh-git android-udev-git;
			sudo pip install doge speedtest-cli;
			wget https://raw.githubusercontent.com/SpotComms/Arch_Install_Commands/master/home/.zshrc;
			chsh -s $(which zsh);
			mkdir -p .config/xfce4/terminal;
			cd .config/xfce4/terminal;
			wget https://raw.githubusercontent.com/SpotComms/Arch_Install_Commands/master/home/.config/xfce4/terminal/terminalrc;
			cd ~; 
			break;;
                No ) break;;
        esac
done
echo -e ${questionColor}"Do you want applications from the development group?"
select yn in "Yes" "No"; do
        case $yn in
                Yes ) 
                	echo -e ${outputColor};
			sudo pacman -S --needed abs android-tools apache-ant bc ccache eclipse-java lib32-readline perl-switch proguard schedtool squashfs-tools;
			yaourt -S android-sdk android-sdk-build-tools android-studio arduino jd-gui launch4j libtinfo repo;
			break;;
                No ) break;;
        esac
done
echo -e ${questionColor}"Do you want applications from the games group?"
select yn in "Yes" "No"; do
        case $yn in
                Yes ) 
                	echo -e ${outputColor};
			sudo pacman -S --needed steam;
			yaourt -S multimc5-git;
			break;;
                No ) break;;
        esac
done
echo -e ${questionColor}"Do you want applications from the l33t hax0ring group?"
select yn in "Yes" "No"; do
        case $yn in
                Yes ) echo -e ${outputColor}; sudo pacman -S --needed nmap wireshark-gtk; break;;
                No ) break;;
        esac
done
echo -e ${questionColor}"Do you want applications from the remote access group?"
select yn in "Yes" "No"; do
        case $yn in
                Yes ) echo -e ${outputColor}; sudo pacman -S --needed remmina freerdp libvncserver nxproxy xorg-server-xephyr; break;;
                No ) break;;
        esac
done
echo -e ${questionColor}"Do you want applications from the security group?"
select yn in "Yes" "No"; do
        case $yn in
                Yes ) 
                	echo -e ${outputColor};
			sudo pacman -S --needed clamav haveged;
			yaourt -S clamtk pgl;
			sudo /bin/bash -c $'echo \'SafeBrowsing Yes\' >> /etc/clamav/freshclam.conf';
			sudo systemctl enable haveged.service;
			break;;
                No ) break;;
        esac
done
echo -e ${questionColor}"Do you want applications from the Yubikey group?"
select yn in "Yes" "No"; do
        case $yn in
                Yes ) 
                	echo -e ${outputColor};
			sudo pacman -S yubikey-neo-manager yubikey-personalization-gui;
			sudo /bin/bash -c $'echo \'ACTION!="add|change", GOTO="u2f_end"\' >> /etc/udev/rules.d/70-u2f.rules';
			sudo /bin/bash -c $'echo \'KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0402|0403|0406|0407|0410", TAG+="uaccess"\' >> /etc/udev/rules.d/70-u2f.rules';
			sudo /bin/bash -c $'echo \'LABEL="u2f_end"\' >> /etc/udev/rules.d/70-u2f.rules';
			break;;
                No ) break;;
        esac
done
echo -e ${questionColor}"Do you want applications from the theming group?"
select yn in "Yes" "No"; do
        case $yn in
                Yes )
                	echo -e ${outputColor};
			sudo pacman -S --needed numix-themes;
			yaourt -S numix-icon-theme-git numix-circle-icon-theme-git;
			break;;
                No ) break;;
        esac
done
echo -e ${questionColor}"Do you want applications from the virtulization group?"
select yn in "Yes" "No"; do
        case $yn in
                Yes )
                	echo -e ${outputColor};
			sudo pacman -S --needed ebtables libvirt openbsd-netcat qemu virt-manager;
			sudo systemctl enable libvirtd.service;
			sudo /bin/bash -c "echo 'polkit.addRule(function(action, subject) { if (action.id == "org.libvirt.unix.manage" && subject.isInGroup("kvm")) { return polkit.Result.YES; } })' >> /etc/polkit-1/rules.d/49-org.libvirt.unix.manager.rules"
			sudo gpasswd -a $USER kvm;
			sudo sed -i 's/MODULES="/MODULES="kvm kvm_intel /' /etc/mkinitcpio.conf;#TODO AMD CPU SUPPORT
			sudo mkinitcpio -p linux;
			break;;
                No ) break;;
        esac
done
echo -e ${infoColor}"END OF APPLICATIONS INSTALLATION"
sleep 3

#Network Tweaks
echo -e ${infoColor}"START OF NETWORK TWEAKS"
echo -e ${outputColor}
sudo pacman -S dnsmasq
sudo sed -i 's/#listen-address=/listen-address=127.0.0.1/' /etc/dnsmasq.conf
sudo sed -i 's/dns=default/dns=dnsmasq/' /etc/NetworkManager/NetworkManager.conf
sudo /bin/bash -c 'echo "net.ipv4.neigh.default.gc_thresh1=256" >> /etc/sysctl.d/99-sysctl.conf'
sudo /bin/bash -c 'echo "net.ipv4.neigh.default.gc_thresh2=2048" >> /etc/sysctl.d/99-sysctl.conf'
sudo /bin/bash -c 'echo "net.ipv4.neigh.default.gc_thresh3=2048" >> /etc/sysctl.d/99-sysctl.conf'
sudo /bin/bash -c 'echo "net.ipv4.tcp_ecn=1" >> /etc/sysctl.d/99-sysctl.conf'
sudo /bin/bash -c 'echo "net.ipv4.tcp_sack=1" >> /etc/sysctl.d/99-sysctl.conf'
sudo /bin/bash -c 'echo "net.ipv4.tcp_dsack=1" >> /etc/sysctl.d/99-sysctl.conf'
sudo /bin/bash -c 'echo "net.netfilter.nf_conntrack_max=1048576" >> /etc/sysctl.d/99-sysctl.conf'
echo -e ${infoColor}"END OF NETWORK TWEAKS"
sleep 3

#Misc Tweaks
echo -e ${infoColor}"START OF MISC TWEAKS"
echo -e ${outputColor}
sudo timedatectl set-ntp true
sudo systemctl enable systemd-timesyncd.service
sudo systemctl restart systemd-timesyncd.service
echo -e ${infoColor}"END OF MISC TWEAKS"
sleep 3

#Finish up
echo -e ${infoColor}"FINISHING UP"
echo -e ${infoColor}"After reboot please login and enjoy your system"
sleep 10
sudo sync
echo -e ${coloroff}
sudo reboot now
