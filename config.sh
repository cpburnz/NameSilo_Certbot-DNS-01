#!/bin/bash
# NameSiloCertbot-DNS-01 0.2.2-cpburnz1
## APIKEY obtained from Namesilo:
APIKEY="YOUR_API_KEY"
CACHE="tmp/"
RESPONSE="$CACHE/namesilo_response.xml"

declare -A base_domain_map
base_domain_map['sub.example.com']='example.com'

mkdir -p "$CACHE"
