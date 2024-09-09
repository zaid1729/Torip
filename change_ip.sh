#!/bin/bash


------------------------------------
------------------------------------
  

  _             _       
 | |           (_)      
 | |_ ___  _ __ _ _ __  
 | __/ _ \| '__| | '_ \ 
 | || (_) | |  | | |_) |
  \__\___/|_|  |_| .__/ 
                 | |    
                 |_|  


                     by : zaid1729       
-------------------------------------
-------------------------------------

LOG_FILE="ip_change.log"
project_dir=$(pwd)


tor_pwd=""
echo "Enter a password for tor network setup"
read -s tor_pwd

echo "Setting environment variable TOR_PWD..."
export TOR_PWD=$tor_pwd


cd $project_dir


echo "Installing Tor package..."
apt-get update
apt-get install -y tor

echo "Creating virtual environment..."
python3 -m venv env
source env/bin/activate

echo "Installing required packages..."
pip install wheel
pip install -r requirements.txt

echo "Making changes as root..."
port_enabled=$(egrep "^ControlPort 9051" /etc/tor/torrc)
if [[ -z "${port_enabled}" ]]; then
    echo "Enabling control port..."
    echo "ControlPort 9051" >> /etc/tor/torrc
fi

echo "Setting hashed Tor password..."
echo HashedControlPassword $(tor --hash-password "${tor_pwd}" | tail -n 1) >> /etc/tor/torrc

echo "Starting Tor service..."
service tor restart

echo "::::: Setup Completed :::::"

IP=$(torify curl -s http://icanhazip.com)
if [ $? -ne 0 ]; then
    echo "Failed to fetch new IP address" | tee -a $LOG_FILE
    exit 1
else
    echo "New IP Address: $IP" | tee -a $LOG_FILE
fi

change_ip() {
    python3 - <<EOF
from stem import Signal
from stem.control import Controller
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def change_ip_address(password):
    logger.info("Changing IP address...")
    with Controller.from_port(port=9051) as controller:
        controller.authenticate(password=password)
        controller.signal(Signal.NEWNYM)

change_ip_address("${TOR_PWD}")
EOF

    if [ $? -ne 0 ]; then
        echo "Failed to change IP address" | tee -a $LOG_FILE
        return 1
    fi

    sleep 10

    NEW_IP=$(torify curl -s http://icanhazip.com)
    if [ $? -ne 0 ]; then
        echo "Failed to fetch new IP address after changing IP" | tee -a $LOG_FILE
        return 1
    else
        echo "Changed IP Address: $NEW_IP" | tee -a $LOG_FILE
    fi
}

# Change IP address every 2 minute
while true; do
    change_ip
    sleep 120
done
