#!/usr/bin/env bash

# check service availability of www.google.com
# some of endpoint can be checked with curl command and "-I" option which can return http status code such as 200 succeed.

curl -I https://portal.azure.com
