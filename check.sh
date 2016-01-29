#!/bin/bash
output="./lecture6/index.html"

response="$(curl -H 'Content-Type: text/html; charset=utf-8' \
  --data-binary @$output \
  https://validator.w3.org/nu/?out=gnu 2>/dev/null)"

if [ -n "$response" ]; then
  echo "$response"
  exit 1
fi
