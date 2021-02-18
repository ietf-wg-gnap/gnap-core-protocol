#!/bin/sh

mkdir -p publish
cp _redirects publish/_redirects
kramdown-rfc2629 -3 draft-ietf-gnap-core-protocol.md > publish/draft-ietf-gnap-core-protocol.xml
xml2rfc --v2v3 publish/draft-ietf-gnap-core-protocol.xml -o publish/draft-ietf-gnap-core-protocol.xml
xml2rfc --text publish/draft-ietf-gnap-core-protocol.xml
xml2rfc --html publish/draft-ietf-gnap-core-protocol.xml
