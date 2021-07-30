# docker-postfix-noreply
[![Build Status](https://www.travis-ci.com/libresquare/docker-postfix-noreply.svg?branch=main)](https://www.travis-ci.com/libresquare/docker-postfix-noreply)

A postfix container for sending outbound emails *within internal trusted network*.

## Enable SASL authentication (PLAIN / LOGIN)
Optional Environment variables
- *SMTP_USER* (Default value: **noreply**)

- *SMTP_PASSWORD* (Default value: a random string generated during startup and printed to stdout)

- *SMTP_PASSWORD_FILE* (a file which contains the **SMTP_PASSWORD**)
  - E.g. /run/secrets/smtp_password


## Disable authentication
Required environment variable
- *NO_AUTH* = **Y**

Optional Environment variables
- *TRUST_NETWORK* (Default value: **10.0.0.0/16**)
