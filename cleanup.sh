#!/bin/bash
# NameSiloCertbot-DNS-01 0.2.2-cpburnz1
## https://stackoverflow.com/questions/59895
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE"  ]; do
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /*  ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"
echo "Received request for" "${CERTBOT_DOMAIN}"
cd ${DIR}
source config.sh

if [[ -v base_domain_map["$CERTBOT_DOMAIN"] ]]; then
  DOMAIN=${base_domain_map["$CERTBOT_DOMAIN"]}
  SUBDOMAIN=$(basename "$CERTBOT_DOMAIN" ".$DOMAIN")
  ACME_RRHOST="_acme-challenge.$SUBDOMAIN"
else
  DOMAIN=${CERTBOT_DOMAIN}
  ACME_RRHOST="_acme-challenge"
fi

ACME_FQDN="_acme-challenge.$CERTBOT_DOMAIN"

## Get current list (updating may alter rrid, etc)
curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > $CACHE$DOMAIN.xml

## Check for existing ACME record
if grep -q "$ACME_FQDN" $CACHE$DOMAIN.xml ; then

	## Get record ID
	RECORD_ID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '$ACME_FQDN' ]" $CACHE$DOMAIN.xml | grep -oP '(?<=<record_id>).*?(?=</record_id>)'`
	## Update DNS record in Namesilo:
	curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$RECORD_ID" > $RESPONSE
	RESPONSE_CODE=`xmllint --xpath "//namesilo/reply/code/text()"  $RESPONSE`
	## Process response, maybe wait

	case $RESPONSE_CODE in
		300)
			echo "ACME challenge record successfully removed"
			;;
		280)
			RESPONSE_DETAIL=`xmllint --xpath "//namesilo/reply/detail/text()"  $RESPONSE`
			echo "Record removal failed."
			echo "Domain: $CERTBOT_DOMAIN"
			echo "rrid: $RECORD_ID"
			echo "reason: $RESPONSE_DETAIL"
			;;
		*)
			RESPONSE_DETAIL=`xmllint --xpath "//namesilo/reply/detail/text()"  $RESPONSE`
			echo "Namesilo returned code: $RESPONSE_CODE"
			echo "Reason: $RESPONSE_DETAIL"
			echo "Domain: $CERTBOT_DOMAIN"
			echo "rrid: $RECORD_ID"
			echo "Response:\n$(cat $RESPONSE)"
			;;
	esac

fi

if [ -f $RESPONSE ] ; then
	rm $RESPONSE
fi
if [ -f $CACHE$DOMAIN.xml ] ; then
	rm $CACHE$DOMAIN.xml
fi
