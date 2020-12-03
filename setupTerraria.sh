#!/bin/bash
# Jacob Eaton - Dec 1st 2020
# Based on a script by James Chambers: https://github.com/TheRemote/RaspberryPiMinecraft

# TShock server version
Version="4.3.26"

# Terminal colors
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

# Prints a line with color using terminal codes
Print_Style() {
  printf "%s\n" "${2}$1${NORMAL}"
}

# Downloads all scripts
Download_Scripts() {
  # Download start.sh from repository
  Print_Style "Grabbing start.sh from repository..." "$YELLOW"
  wget -O start.sh https://raw.githubusercontent.com/jacob-eaton/TShock-Bash-Scripts/main/start.sh
  chmod +x start.sh
  sed -i "s:dirname:$DirName:g" start.sh

  # Download stop.sh from repository
  echo "Grabbing stop.sh from repository..."
  wget -O stop.sh https://raw.githubusercontent.com/jacob-eaton/TShock-Bash-Scripts/main/stop.sh
  chmod +x stop.sh

  # Download restart.sh from repository
  echo "Grabbing restart.sh from repository..."
  wget -O restart.sh https://raw.githubusercontent.com/jacob-eaton/TShock-Bash-Scripts/main/restart.sh
  chmod +x restart.sh
  sed -i "s:dirname:$DirName:g" restart.sh
}

# Updates Terraria service
Update_Service() {
  sudo wget -O /etc/systemd/system/terraria.service https://raw.githubusercontent.com/jacob-eaton/TShock-Bash-Scripts/main/terraria.service
  sudo chmod +x /etc/systemd/system/terraria.service
  sudo sed -i "s/replace/$UserName/g" /etc/systemd/system/terraria.service
  sudo sed -i "s:dirname:$DirName:g" /etc/systemd/system/terraria.service
  sudo systemctl daemon-reload
  Print_Style "Terraria can automatically start at boot if you wish." "$CYAN"
  echo -n "Start Terraria server at startup automatically (y/n)?"
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    sudo systemctl enable terraria.service
  fi
}

# Gets variables for creating a new world
create_world() {
  printf "\n%-10s %s\n" "1" "Small"
  printf "%-10s %s\n" "2" "Medium"
  printf "%-10s %s\n" "3" "Large"
  echo -n "Choose size: "
  read size
  printf "\n%-10s %s\n" "1" "Classic"
  printf "%-10s %s\n" "2" "Expert"
  printf "%-10s %s\n" "3" "Master"
  printf "%-10s %s\n" "4" "Journey"
  echo -n "Choose difficulty: "
  read difficulty
  printf "\n%-10s %s\n" "1" "Random"
  printf "%-10s %s\n" "2" "Corrupt"
  printf "%-10s %s\n" "3" "Crimson"
  printf "Choose world evil: "
  read worldEvil
  printf "\nEnter world name: "
  read worldName
  printf "\nEnter Seed (Leave blank for random): "
  read seed
}
#################################################################################################

Print_Style "TShock Server installation script by Jacob Eaton December 1st 2020" "$MAGENTA"
Print_Style "Version $Version will be installed.  To change this, open setupTerraria.sh and change the \"Version\" variable to the version you want to install." "$MAGENTA"
Print_Style "Don't forget to set up port forwarding on your router!  The default port is 7777" "$MAGENTA"

# Install dependencies needed to run Terraria in the background
Print_Style "Installing screen, sudo, net-tools, wget..." "$YELLOW"
if [ ! -n "$(which sudo)" ]; then
  apt-get update && apt-get install sudo -y
fi
sudo apt-get update
sudo apt-get install mono-complete -y
sudo apt-get install screen -y
sudo apt-get install unzip -y

# Check to see if Terraria directory already exists, if it does then reconfigure existing scripts
if [ -d "terraria" ]; then
  Print_Style "Directory terraria already exists!  Updating scripts and configuring service ..." "$YELLOW"
  # Get Home directory path and username
  cd terraria
  DirName=$(readlink -e ~)
  UserName=$(whoami)

  # Update Terraria server scripts
  Download_Scripts

  # Service configuration
  Update_Service

  Print_Style "Terraria installation scripts have been updated to the latest version!" "$GREEN"
  exit 0
fi

# Create server directory
Print_Style "Creating terraria server directory..." "$YELLOW"
cd ~
mkdir terraria
cd terraria

# Get Home directory path and username
DirName=$(readlink -e ~)
UserName=$(whoami)

# Retrieve latest release of TShock
Print_Style "Getting latest TShock release..." "$YELLOW"
wget -O tshock.zip https://github.com/NyxStudios/TShock/releases/download/v$Version/tshock_$Version.zip
unzip tshock.zip
rm tshock.zip

# Download Terraria server scripts
Download_scripts

# Service configuration
Update_Service

# Look for existing world files
{
  cd ~/.local/share/Terraria/Worlds/
  worldFiles=`find ./*.wld -maxdepth 1 -type f -not -path '*/\.*' | sed 's/^\.\///g' | sort`
} &> /dev/null

if [ -z "$worldFiles" ]; then # If no worlds files exist
  echo "No worlds found, creating one."
  create_world
else # If world files exist
  cnt=0
  for eachFile in $worldFiles
  do
    #echo $eachfile " - " $cnt
    printf "%-10s %s\n" $cnt $eachFile
    let "cnt+=1"
  done
  printf "%-10s %s\n" "n" "New World"
  printf "Choose world: "
  read selectWorld
  if [ "$selectWorld" != "${selectWorld#[Nn]}" ]; then
    create_world
  fi
  printf "\nMax players (press enter for 16): "
  read players
  printf "\nServer port (press enter for 7777): "
  read port
  printf "\nAutomatically forward port? (y/n): "
  read autoForward
  printf "\nServer password (press enter for none): "
  read password
fi

# Finished!
Print_Style "Setup is complete.  Starting Terraria server..." "$GREEN"
sudo systemctl start terraria.service

# Wait up to 30 seconds for server to start
StartChecks=0
while [ $StartChecks -lt 30 ]; do
  if screen -list | grep -q "terraria"; then
    screen -r terraria
    break
  fi
  sleep 1
  StartChecks=$((StartChecks + 1))
done

if [[ $StartChecks == 30 ]]; then
  Print_Style "Server has failed to start after 30 seconds." "$RED"
else
  screen -r terraria
fi
