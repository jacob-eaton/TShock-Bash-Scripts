#!/bin/bash
# Jacob Eaton - Dec 1st 2020
# Based on a script by James Chambers: https://github.com/TheRemote/RaspberryPiMinecraft
# Terraria Server Start Script

# Check if server is already running
if screen -list | grep -q "terraria"; then
    echo "Server is already running!  Type screen -r terraria to open the console"
    exit 1
fi

# Check if network interfaces are up
NetworkChecks=0
DefaultRoute=$(route -n | awk '$4 == "UG" {print $2}')
while [ -z "$DefaultRoute" ]; do
    echo "Network interface not up, will try again in 1 second";
    sleep 1;
    DefaultRoute=$(route -n | awk '$4 == "UG" {print $2}')
    NetworkChecks=$((NetworkChecks+1))
    if [ $NetworkChecks -gt 20 ]; then
        echo "Waiting for network interface to come up timed out - starting server without network connection ..."
        break
    fi
done

# Switch to server directory
cd dirname/terraria/

# Start the server
echo "Starting Terraria server.  To view window type screen -r terraria."
echo "To minimize the window and let the server run in the background, press Ctrl+A then Ctrl+D"
screen -dmS terraria mono --server --gc=sgen -O=all TerrariaServer.exe

# Choose World
screen -Rd terraria -X stuff "1^M"

# Max Players
screen -Rd terraria -X stuff "10^M"

# Server Port
screen -Rd terraria -X stuff "^M"

# Automatically Forward Port
screen -Rd terraria -X stuff "y^M"

# Server Password
screen -Rd terraria -X stuff "^M"



