#!/bin/bash
###########################
# Workaround for Dungeon defender Eternity on linux
# --------------------------------------------------
# Big thanks for the community arround Valve!
# Thanks for your feedback, reports...
###########################

purple='\e[0;35m'
yellow='\e[1;33m'
nc='\e[0m'

# Update your locate
echo "Settings up PATHS..."
sudo updatedb

# SET PATH :
STEAMPATH=`locate "steam.pipe" | head -1 | sed "s/\/steam\.pipe/\//"`
STEAM_LIB_PATH=`locate steam-runtime/i386 | head -1`
STEAMAPPS=`find ${STEAMPATH} -name SteamApps`
# In case of the game path is not the default path :
DUNDEF_LIB_PATH=`locate DunDefEternity | grep "/DunDefEternity/Binaries/Linux" | head -1`
DUNDEF_LAUNCHER_PATH=`locate DunDefEternityLauncher | sort -u`

# List of package used for Debian :
apt="libgconf-2-4:i386 libvorbisfile3:i386 libsfml-dev:i386 libcrypto++-dev:i386 curl:i386 libcurl4-openssl-dev:i386 \
    libfreetype6:i386 libxrandr2:i386 libgtk2.0-0:i386 libpango-1.0-0:i386 libnss3-dev:i386 libpangocairo-1.0-0:i386 \
    libasound2-dev:i386 libgdk-pixbuf2.0-0:i386"
# List of package used for RedHat :
yum="GConf2.i686 libvorbis.i686 SFML.i686 SFML-devel.i686 cryptopp.i686 libcurl.i686 libcurl-devel.i686 \
    freetype.i686 freetype-devel.i686 libXrandr.i686 libXrandr-devel.i686 gtk2.i686 gtk2-devel.i686 \
    pango.i686 pango-devel.i686 cairo.i686 cairo-devel.i686 gtk-pixbuf2-devel.i686 gtk-pixbuf2.i686"
# List of package used for Arch :
pacman="gconf lib32-libvorbis sfml crypto++ lib32-libgcrypt curl lib32-nss lib32-openssl lib32-libfreetype \
    lib32-libxrandr lib32-gtk2 lib32-pango libtiger lib32-gdk-pixbuf2"

# Function used to ask if the user want to launch the game :
function LaunchGame () {
    local step=true
    while ${step}; do
        echo -e "${yellow}Do you want launch Dungeon Defender?(Y/N)${nc}"
        read answer
        case ${answer} in
            Y|y)
                steam steam://rungameid/302270 &
                step=false
                ;;
            N|n)
                echo -e "${yellow}Quiting...${nc}"
                step=false
                ;;
            *)
                echo -e "${yellow}Please use Y or N.${nc}"
                step=true
                ;;
        esac
    done
}

function CheckLibs () {
    ## Check for available libs :
    echo -e "${purple}------------------------------------------------------${nc}"
    echo -e "${yellow}Installed Libs :${nc}"
    echo `ldd ${DUNDEF_LAUNCHER_PATH} | grep lib  | tr "\t" " " | cut -d"=" -f1`
    echo -e "${purple}------------------------------------------------------${nc}"

    ## Check for unavailable libs :
    echo -e "${yellow}Missing Libs :${nc}"
    echo `ldd ${DUNDEF_LAUNCHER_PATH} | grep "not found" | tr "\t" " " | cut -d"=" -f1`
    echo -e "${purple}------------------------------------------------------${nc}"

    echo ""
    echo -e "${yellow}Directories used for your libs${nc}"
    # Prints out all directory used to provide your libs
    sudo ldconfig -v 2>/dev/null | grep -v ^$'\t'
    echo -e "${purple}------------------------------------------------------${nc}"
}

function SymLinkFix () {
    CheckLibs

    ## Doing job
    ln -sf ${STEAM_LIB_PATH}/usr/lib/i386-linux-gnu/* ${DUNDEF_LIB_PATH}
    ln -sf ${STEAM_LIB_PATH}/lib/i386-linux-gnu/* ${DUNDEF_LIB_PATH}

    clear
    echo -e "${yellow}Symlinking Done!${nc}"
    echo -e "${purple}------------------------------------------------------${nc}"
    echo -e "${yellow}Missing libs :${nc}"
    echo `ldd ${DUNDEF_LAUNCHER_PATH} | grep "not found" | tr "\t" " " | cut -d"=" -f1`
    echo -e "${purple}------------------------------------------------------${nc}"
}

function PandaFix {
    CheckLibs

    # Installing Main libs
    ## Debian Flavours
    if [[ -x "$(which aptitude)" ]]; then
        echo -e "${yellow}Add i386 arch${nc}"
        sudo dpkg --add-architecture i386
        echo -e "${yellow}Installing missing libs :${nc}"
        sudo aptitude update && sudo aptitude install ${apt}

    elif [[ -x "$(which apt-get)" ]]; then
        echo -e "${yellow}Add i386 arch"
        sudo dpkg --add-architecture i386
        echo -e "${yellow}Installing missing libs :${nc}"
        sudo apt-get update && sudo apt-get install ${apt}
    fi

    ## Red Hat Flavours
    if [[ -x "$(which yum)" ]]; then
        echo -e "${yellow}Installing missing libs :${nc}"
        sudo yum update && sudo yum install ${yum}
    fi

    ## ArchLinux Flavours
    if [[ -x "$(which pacman)" ]]; then
        echo -e "${yellow}Enabling 'MultiLib' Repo :${nc}"
        sudo sed 's/#\[multilib\]/\[multilib\]/g;s/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/g' -i /etc/pacman.conf
        echo -e "${yellow}Installing missing libs :${nc}"
        echo -e "${yellow}/!\ Support of pacman package manager is currently in testing...${nc}"
        sudo pacman -Syy && sudo pacman -S ${pacman}
    fi

    echo -e "${purple}------------------------------------------------------${nc}"
    echo -e "${yellow}Missing Libs :${nc}"
    echo `ldd ${DUNDEF_LAUNCHER_PATH} | grep "not found" | tr "\t" " " | cut -d"=" -f1`
    echo -e "${purple}------------------------------------------------------${nc}"
}

Cleaning () {
    echo -e "${yellow}Cleaning symlink fix...${nc}"
    find "$DUNDEF_LIB_PATH" -maxdepth 1 -type l -exec rm -f {} \;
    echo -e "${yellow}Cleaning done...${nc}"
}

#Show menu :
while true; do
    echo -e "${purple}+----------------------------+${nc}"
    echo -e "${purple}|${nc} ${yellow}[ Choose your workaround ]${nc} ${purple}|${nc}"
    echo -e "${purple}+----------------------------+------------------------${nc}"
    echo -e "${purple}|${nc} ${yellow}[1] -> SymLink Fix   --> Create all symlinks needed to fix your issue. (All Linux OS)${nc}"
    echo -e "${purple}|${nc} ${yellow}[2] -> PandaWan Fix  --> Install all package needed for your game. (All Linux OS)${nc}"
    echo -e "${purple}|${nc} ${yellow}[3] -> ShowMyLibs    --> Show all directories used to provide your Libs (All Linux OS)${nc}"
    echo -e "${purple}|${nc} ${yellow}[4] -> Cleaning      --> Remove Symlink Fix!${nc}"
    echo -e "${purple}|${nc} ${yellow}[Q] -> Quit          --> Exit...${nc}"
    echo -e "${purple}+-----------------------------------------------------${nc}"
    echo -e "${yellow}Your choice : ${nc}"
    read choice

    case ${choice} in
        1)
            SymLinkFix
            LaunchGame
            ;;
        2)
            PandaFix
            LaunchGame
            ;;
        3)
            # Prints out all directories used to provide your libs
            CheckLibs
            ;;
        4)
            Cleaning
            ;;
        Q|q)
            exit 0;
            ;;
        *)
            echo -e "${yellow}${choice} is not available"
            ;;
    esac
done