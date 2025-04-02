#!/bin/bash

echo "Updating package list and installing dependencies..."
sudo apt update

# Install essential dependencies
sudo apt install -y curl wget unzip golang-go 2>/dev/null

# Install amass, try apt first, fallback to snap if suggested
amass_output=$(sudo apt install -y amass 2>&1)
amass_status=$?
if [ $amass_status -ne 0 ] && echo "$amass_output" | grep -q "Try \"snap install amass\""; then
    echo "Installing amass via snap..."
    sudo snap install amass
fi

# Install whois
echo "Installing whois..."
sudo apt install -y whois

# Install subfinder
if ! command -v subfinder &> /dev/null; then
    echo "Installing subfinder..."
    curl -s https://api.github.com/repos/projectdiscovery/subfinder/releases/latest | grep "browser_download_url.*linux_amd64.zip" | cut -d : -f 2,3 | tr -d '"' | wget -qi -
    unzip subfinder*.zip
    chmod +x subfinder
    sudo mv subfinder /usr/local/bin/
    rm subfinder*.zip
fi

# Install assetfinder
if ! command -v assetfinder &> /dev/null; then
    echo "Installing assetfinder..."
    go install github.com/tomnomnom/assetfinder@latest
    sudo mv ~/go/bin/assetfinder /usr/local/bin/
fi

# Install httprobe
if ! command -v httprobe &> /dev/null; then
    echo "Installing httprobe..."
    go install github.com/tomnomnom/httprobe@latest
    sudo mv ~/go/bin/httprobe /usr/local/bin/
fi

# Install gowitness
if ! command -v gowitness &> /dev/null; then
    echo "Installing gowitness..."
    go install github.com/sensepost/gowitness@latest
    sudo mv ~/go/bin/gowitness /usr/local/bin/
fi

# Install waybackurls
if ! command -v waybackurls &> /dev/null; then
    echo "Installing waybackurls..."
    go install github.com/tomnomnom/waybackurls@latest
    sudo mv ~/go/bin/waybackurls /usr/local/bin/
fi

echo "All tools and dependencies installed successfully!"
