#!/bin/sh

mkdir -p publish
cp _redirects publish/_redirects
kramdown-rfc2629 -3 draft-ietf-gnap-core-protocol.md > publish/draft-ietf-gnap-core-protocol.xml
xml2rfc --v3 --text publish/draft-ietf-gnap-core-protocol.xml
xml2rfc --v3 --html publish/draft-ietf-gnap-core-protocol.xml
