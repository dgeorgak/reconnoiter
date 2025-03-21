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
assetfinder $domain >> $subdomain_path/found.txt

# Get subdomains with amass
# adding "-r [DNS]" to avoid errors if run within a VM
echo -e "${RED} [+] Running amass... ${RESET}this might take awhile :|"
amass enum -active -d $domain -r 8.8.8.8 > $subdomain_path/amass_output.txt
cat $subdomain_path/amass_output.txt | cut -d ' ' -f1 >> $subdomain_path/found.txt

# Sort and remove duplicates, seperate between domain and non-domain findings
echo -e "${RED} [+] Finding alive subdomains... ${RESET}"
cat $subdomain_path/found.txt | grep $domain | sort -u > $subdomain_path/domain_results.txt
cat $subdomain_path/found.txt | grep -v $domain | sort -u > $subdomain_path/non-domain_results.txt

# Use httprobe to find the alive subdomains
cat $subdomain_path/domain_results.txt | httprobe | grep https | tee $subdomain_path/alive.txt

# Use gowitness to take screenshots of the subdomains
echo -e "${RED} [+] Taking screenshots... ${RESET}"
gowitness file -f $subdomain_path/alive.txt -P $screenshot_path/ --no-http --disable-db

# cleanup
rm  $subdomain_path/amass_output.txt  $subdomain_path/found.txt
