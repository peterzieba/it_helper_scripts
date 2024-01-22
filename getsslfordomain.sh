#!/bin/bash
echo "This will create SSL certificate requests for a domain and update nginx configuration automatically."
#The following Ubuntu packages are assumed to be present:
#apt-get install nginx certbot python3-certbot-nginx

#It is also assumed that the machine this is being run on is the nginx server and that the domain is already pointed to this server.

if [ "$#" -eq 0 ]; then
    echo "No arguments were passed."
    read -p "Enter domain name: " domain
elif [ "$#" -eq 1 ]; then
    domain=$1
fi

number_of_periods=$(echo "${domain//[^.]}" | wc -c)
# Since wc -c includes a newline character in its count, we subtract 1
number_of_periods=$((number_of_periods - 1))

if [ ${number_of_periods} -eq 1 ]; then
    echo "Assuming you want www.${domain} created as well"
    certbot --nginx -d ${domain} -d www.${domain}
else
    echo "Not creating a reqest for www"
    certbot --nginx -d ${domain}
fi
