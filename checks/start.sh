#!/bin/sh
# The starting user's access key works, and the load balancer serves the web application.
set -eu
arn=$(env -u AWS_SESSION_TOKEN -u AWS_PROFILE -u AWS_CREDENTIAL_EXPIRATION \
  AWS_ACCESS_KEY_ID="$ISOLOOM_OUTPUT_LARA_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$ISOLOOM_OUTPUT_LARA_SECRET_KEY" \
  aws sts get-caller-identity --query Arn --output text)
case "$arn" in */lara*) ;; *) echo "the key authenticates as $arn" >&2; exit 1 ;; esac
dns=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?starts_with(LoadBalancerName, 'cg-lb-rce-web-app')].DNSName | [0]" --output text)
curl -fsS -m 10 -o /dev/null "http://$dns/"
