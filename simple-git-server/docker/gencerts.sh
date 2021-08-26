#!/usr/bin/env bash

openssl req \
    -newkey rsa:2048 \
    -x509 \
    -nodes \
    -keyout privkey.pem \
    -new \
    -out cert.pem \
    -subj /CN=git.default.svc \
    -reqexts SAN \
    -extensions SAN \
    -config <(cat /etc/ssl//openssl.cnf \
        <(printf '[SAN]\nsubjectAltName=DNS:git.default.svc,DNS:localhost')) \
    -sha256 \
    -days 3650
