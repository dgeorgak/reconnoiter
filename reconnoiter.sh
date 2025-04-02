#!/bin/bash

cloud_recon=false
update_SNI_IPs=true
domain=""

# Parse command line arguments
for arg in "$@"; do
    if [[ "$arg" == "-c" ]]; then
        cloud_recon=true
    elif [[ "$arg" == "--no-update" ]]; then
        update_SNI_IPs=false
    elif [[ -z "$domain" ]]; then
        domain="$arg"
    fi
done

# Check if domain is provided
if [[ -z "$domain" ]]; then
    echo "Usage: $0 [targetDomain] [-c] [--no-update]"
    exit 1
fi

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
echo -e "${RED} [+] Running amass... ${RESET}this might take awhile :|"
# adding "-r [DNS]" to avoid errors if run within a VM
amass enum -active -d $domain -r 8.8.8.8 > $subdomain_path/amass_output.txt
cat $subdomain_path/amass_output.txt | cut -d ' ' -f1 >> $subdomain_path/found.txt

# Get subdomains with waybackurls
echo -e "${RED} [+] Running waybackurls... ${RESET}"
waybackurls $domain | sed 's/^https\?:\/\///' | cut -d '/' -f1 >> $subdomain_path/found.txt

# Cloud Recon
if [[ "$cloud_recon" == true ]]; then
    if [[ "$update_SNI_IPs" == true ]]; then
        # Download latest SNI IP ranges from kaeferjaeger
        echo -e "${RED} [+] Downloading SNI IPs from kaefetjaeger... ${RESET}this might take a while :|"
        echo -e "Downloading Amazon SNI IPs"
        wget https://kaeferjaeger.gay/sni-ip-ranges/amazon/ipv4_merged_sni.txt -O amazon-ipv4-sni-ip.txt
        echo -e "Downloading Digital Ocean SNI IPs"
        wget https://kaeferjaeger.gay/sni-ip-ranges/digitalocean/ipv4_merged_sni.txt -O DO-ipv4-sni-ip.txt
        echo -e "Downloading Google SNI IPs"
        wget https://kaeferjaeger.gay/sni-ip-ranges/google/ipv4_merged_sni.txt -O google-ipv4-sni-ip.txt
        echo -e "Downloading Microsoft SNI IPs"
        wget https://kaeferjaeger.gay/sni-ip-ranges/microsoft/ipv4_merged_sni.txt -O microsoft-ipv4-sni-ip.txt
        echo -e "Downloading Oracle SNI IPs"
        wget https://kaeferjaeger.gay/sni-ip-ranges/oracle/ipv4_merged_sni.txt -O oracle-ipv4-sni-ip.txt
    fi
    cat *.txt | grep -F $domain | awk -F '-- ' '{print $2}' | tr ' ' '\n' | tr '[' ' ' | sed 's/ //' | sed 's/\]//' | grep -F $domain | sort -u > $subdomain_path/cloud.txt
    cat cloud.txt >> $subdomain_path/found.txt
fi

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