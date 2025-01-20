#!/bin/bash

domain=$1
RED="\033[1;31m"
RESET="\033[0m"

# Create the domain directory if it doesn't already exist
if [ ! -d "$domain" ]; then
    mkdir $domain
fi

# Create subdirectories if they don't already exist
info_path=$domain/info
subdomain_path=$domain/subdomains
screenshot_path=$domain/screenshots

for dir in $info_path $subdomain_path $screenshot_path; do
    if [ ! -d "$dir" ]; then
        mkdir $dir
    fi
done

# Get domain information with whois
echo -e "${RED} [+] Running whois... ${RESET}"
whois $domain > $info_path/whois.txt

# Get subdomains with subfinder
echo -e "${RED} [+] Running subfinder... ${RESET}"
subfinder -d $domain > $subdomain_path/found.txt

# Get subdomains with assetfinder
echo -e "${RED} [+] Running assetfinder... ${RESET}"
assetfinder $domain | grep $domain >> $subdomain_path/found.txt

# Get subdomains with assetfinder
echo -e "${RED} [+] Running amass... ${RESET}"
amass enum -d $domain >> $subdomain_path/found.txt

# Sort and remove duplicates, use httprobe to find the alive subdomains
echo -e "${RED} [+] Finding alive subdomains... ${RESET}"
cat $subdomain_path/found.txt | grep $domain | sort -u | httprobe | grep https | tee -a $subdomain_path/alive.txt

# Use gowitness to take screenshots of the subdomains
echo -e "${RED} [+] Taking screenshots... ${RESET}"
gowitness scan file -f $subdomain_path/alive.txt -s $screenshot_path/ --no-http

