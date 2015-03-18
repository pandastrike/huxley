#!/bin/bash

#
# Example script for setting a DNS name using bash
# This script will register the name `test.sparkles.cluster`
# and set it to 10.1.2.3, and poll every 5 seconds until the
# changes have been synchronized.
#

KICK_SERVER="http://localhost:8080"

curl -XPOST $KICK_SERVER/records -d '{
    "hostname": "test.sparkles.cluster",
    "ip_address": "10.1.2.3",
    "type": "A"
  }' -H 'Content-Type: application/vnd.kick.record+json'

until curl $KICK_SERVER/record/test.sparkles.cluster | grep -o 'INSYNC'; do
  sleep 5
done

