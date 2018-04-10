#!/usr/bin/env bash
set -x

BASE_PATH="/etc/letsencrypt/live/jenkins.gomesc.com.br"

DEST_PATH="/etc/jenkins/cert"

FILES="cert.pem chain.pem fullchain.pem privkey.pem"

for file in $FILES; do

  cp "$BASE_PATH/$file" "$DEST_PATH/$file"
  chown jenkins:jenkins "$DEST_PATH$file"

done;

# convert to RSA, jenkins only accepts it
openssl rsa -in "$DEST_PATH/privkey.pem" -out "$DEST_PATH/privkey-rsa.pem"


# restart jenkins to enable the new certs
service jenkins restart

