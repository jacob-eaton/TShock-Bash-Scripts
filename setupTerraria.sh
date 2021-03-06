#!/bin/bash
# Jacob Eaton - Dec 13th 2020
# Based on a script by James Chambers: https://github.com/TheRemote/RaspberryPiMinecraft

# TShock server version
Version="4.4.0-pre15"
zipName="Tshock4.4.0_Pre15_Terraria1.4.1.2"

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
  # Remove existing scripts
  rm terraria/start.sh terraria/stop.sh terraria/restart.sh

  # Download start.sh from repository
  Print_Style "Grabbing start.sh from repository..." "$YELLOW"
  wget -O start.sh https://raw.githubusercontent.com/jacob-eaton/TShock-Bash-Scripts/main/start.sh
  chmod +x start.sh
  sed -i "s:dirname:$DirName:g" start.sh

  # Download stop.sh from repository
  Print_Style "Grabbing stop.sh from repository..." "$YELLOW"
  wget -O stop.sh https://raw.githubusercontent.com/jacob-eaton/TShock-Bash-Scripts/main/stop.sh
  chmod +x stop.sh

  # Download restart.sh from repository
  Print_Style "Grabbing restart.sh from repository..." "$YELLOW"
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
  screen -Rd terraria -X stuff "n^M"
  printf "%b\n%-10s %s\n" "$CYAN" "1" "Small"
  printf "%-10s %s\n" "2" "Medium"
  printf "%-10s %s\n%b" "3" "Large" "$NORMAL"
  echo -n "Choose size: "
  read size
  screen -Rd terraria -X stuff "$size^M"
  printf "%b\n%-10s %s\n" "$CYAN" "1" "Classic"
  printf "%-10s %s\n" "2" "Expert"
  printf "%-10s %s\n" "3" "Master"
  printf "%-10s %s\n%b" "4" "Journey" "$NORMAL"
  echo -n "Choose difficulty: "
  read difficulty
  screen -Rd terraria -X stuff "$difficulty^M"
  #The latest TShock does not appear to ask for world evil, not sure if this is a bug...
  #printf "%b\n%-10s %s\n" "$CYAN" "1" "Random"
  #printf "%-10s %s\n" "2" "Corrupt"
  #printf "%-10s %s\n%b" "3" "Crimson" "$NORMAL"
  #echo -n "Choose world evil: "
  #read worldEvil
  #screen -Rd terraria -X stuff "$worldEvil^M"
  echo ""
  echo -n "Enter world name: "
  read worldName
  screen -Rd terraria -X stuff "$worldName^M"
  echo ""
  echo -n "Enter Seed (Leave blank for random): "
  read answer
  if [ -z $answer ]; then
    seed=""
  else
    seed=$answer
  fi
  screen -Rd terraria -X stuff "$seed^M"
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
wget -O tshock.zip https://github.com/NyxStudios/TShock/releases/download/v$Version/$zipName.zip
unzip -o -j tshock.zip
rm tshock.zip

# Download Terraria server scripts
Download_Scripts

# Service configuration
Update_Service

# Start the server
screen -dmS terraria mono --server --gc=sgen -O=all TerrariaServer.exe

# Wait up to 30 seconds for server to start
StartChecks=0
while [ $StartChecks -lt 30 ]; do
  if screen -list | grep -q "terraria"; then
    break
  fi
  sleep 1
  StartChecks=$((StartChecks + 1))
done

if [[ $StartChecks == 30 ]]; then
  Print_Style "Server has failed to start after 30 seconds." "$RED"
  exit 0
fi

# Look for existing world files
{
  cd ~/.local/share/Terraria/Worlds/
  worldFiles=`find ./*.wld -maxdepth 1 -type f -not -path '*/\.*' | sed 's/^\.\///g' | sort`
} &> /dev/null

# Return to Terraria directory
cd "$DirName/terraria"

echo ""
if [ -z "$worldFiles" ]; then # If no worlds files exist
  Print_Style "No worlds found, creating one." "$YELLOW"
  Print_Style "Enter world settings..." "$YELLOW"
  create_world
  screen -Rd terraria -X stuff "1^M"
  worldSelect=1
else
  cnt=1
  echo ""
  for eachFile in $worldFiles
  do
    printf "%b%-10s %s\n" "$CYAN" $cnt $eachFile
    let "cnt+=1"
  done
  printf "%-10s %s\n%b" "n" "New World" "$NORMAL"
  echo -n "Choose world: "
  read worldSelect
  sed -i "s:worldSelect:$worldSelect:g" start.sh
  if [ "$worldSelect" != "${worldSelect#[Nn]}" ]; then
    create_world
    newFiles=("$worldName.wld")
    for eachFile in $worldFiles
    do
      newFiles+=($eachFile)
    done
    newFiles=($(for each in ${newFiles[@]}; do echo $each; done | sort))
    echo ${newFiles[0]}
    for i in "${!newFiles[@]}"; do
      if [[ "${newFiles[$i]}" = "$worldName.wld" ]]; then
        worldSelect=$(( $i + 1 ));
      fi
    done
  fi
  screen -Rd terraria -X stuff "$worldSelect^M"
fi
sed -i "s:worldSelect:$worldSelect:g" start.sh

echo ""
Print_Style "Enter server settings..." "$YELLOW"
echo -n "Max players (press enter for 16): "
read answer
if [ -z $answer ]; then
  maxPlayers=""
else
  maxPlayers=$answer
fi
sed -i "s:maxPlayers:$maxPlayers:g" start.sh
screen -Rd terraria -X stuff "$maxPlayers^M"
echo ""
echo -n "Server port (press enter for 7777): "
read answer
if [ -z $answer ]; then
  serverPort=""
else
  serverPort=$answer
fi
sed -i "s:serverPort:$serverPort:g" start.sh
screen -Rd terraria -X stuff "$serverPort^M"
echo ""
echo -n "Automatically forward port? (y/n): "
read autoForward
sed -i "s:autoForward:$autoForward:g" start.sh
screen -Rd terraria -X stuff "$autoForward^M"
echo ""
echo -n "Server password (press enter for none): "
read answer
if [ -z $answer ]; then
  serverPassword=""
else
  serverPassword=$answer
fi
sed -i "s:serverPassword:$serverPassword:g" start.sh

screen -Rd terraria -X stuff "$serverPassword^M"

# Finished!
echo ""
Print_Style "Setup is complete. Going to Terraria server..." "$GREEN"
screen -r terraria

