#!/bin/bash
# Jacob Eaton - Dec 1st 2020
# Based on a script by James Chambers: https://github.com/TheRemote/RaspberryPiMinecraft
# Terraria Server Stop Script

# Check if server is running
if ! screen -list | grep -q "terraria"; then
  echo "Server is not currently running!"
  exit 1
fi

# Stop the server
echo "Preparing to restart Terraria server..."
screen -Rd terraria -X stuff "say Restarting the server in 5 minutes...^M"
echo "Restarting in 5 minutes."
sleep 240;
screen -Rd terraria -X stuff "say Restarting the server in 1 minute...^M"
echo "Restarting in 1 minute."
sleep 50;
screen -Rd terraria -X stuff "say Restarting the server in 10 seconds...^M"
echo "Restarting in 10 seconds."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server in 9 seconds...^M"
echo "Restarting in 9 seconds."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server in 8 seconds...^M"
echo "Restarting in 8 seconds."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server in 7 seconds...^M"
echo "Restarting in 7 seconds."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server in 6 seconds...^M"
echo "Restarting in 6 seconds."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server in 5 seconds...^M"
echo "Restarting in 5 seconds."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server in 4 seconds...^M"
echo "Restarting in 4 seconds."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server in 3 seconds...^M"
echo "Restarting in 3 seconds."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server in 2 seconds...^M"
echo "Restarting in 2 seconds."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server in 1 second...^M"
echo "Restarting in 1 second."
sleep 1;
screen -Rd terraria -X stuff "say Restarting the server now...^M"
screen -Rd terraria -X stuff "off^M"

# Wait up to 30 seconds for server to close
StopChecks=0
while [ $StopChecks -lt 30 ]; do
  if ! screen -list | grep -q "terraria"; then
    break
  fi
  sleep 1;
  StopChecks=$((StopChecks+1))
done

# Force quit if server is still open
if screen -list | grep -q "terraria"; then
  echo "Terraria server still hasn't closed after 30 seconds, closing screen manually"
  screen -S minecraft -X quit
fi

echo "Terraria server stopped."

./start.sh
