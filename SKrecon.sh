#!/bin/bash

domain=$1

if [ -z "$domain" ]; then
    echo "Usage: $0 example.com"
    exit 1
fi

echo "[+] Scanning subdomain with assetfinder"
assetfinder --subs-only $domain | tee -a subdomain.txt
echo "[+] Scanning subdomain from rapiddns.io"
curl -s "https://rapiddns.io/subdomain/$domain?full=1#result" | grep "<td><a" | cut -d '"' -f 2 | grep http | cut -d '/' -f3 | sed 's/#results//g' | sort -u | tee -a subdomain.txt
echo "[+] Scanning subdomain from dns.bufferover.run"
curl -s https://dns.bufferover.run/dns?q=.$domain |jq -r .FDNS_A[]|cut -d',' -f2|sort -u | tee -a subdomain.txt
echo "[+] Scanning subdomain from dns.bufferover.run"
curl -s "https://riddler.io/search/exportcsv?q=pld:$domain" | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee -a subdomain.txt
echo "[+] Scanning subdomain from jldc.me"
curl -s "https://jldc.me/anubis/subdomains/$domain" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee -a subdomain.txt
echo "[+] Scanning subdomain from securitytrails.com"
curl -s "https://securitytrails.com/list/apex_domain/$domain" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | grep ".$domain" | sort -u | tee -a subdomain.txt
echo "[+] Scanning subdomain from crt.sh"
curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee -a subdomain.txt
echo "[+] Finding live domain and removing duplicate"
cat subdomain.txt | sort -u > unique-subdomains.txt
cat unique-subdomains.txt | httprobe | tee live-domain.txt
echo "[+] Screenshoting live domains..."
cat unique-subdomains.txt | uniq | httpx -silent -mc 200,302,404,403,401,400 -threads 70 | cut -d "/" -f 3 | uniq | aquatone -scan-timeout 3000 -threads 5 -silent -screenshot-timeout 50000 -http-timeout 20000 -out subdomains-screenshots
rm subdomain.txt
count=$(cat live-domain.txt | wc -l)
echo "[+] Got $count live subdomain."
echo "by @l33t_En0ugh"
