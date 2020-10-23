#!/bin/sh

kramdown-rfc2629 --v3 draft-ietf-gnap-core-protocol.md > draft-ietf-gnap-core-protocol.xml
xml2rfc --v2v3 draft-ietf-gnap-core-protocol.xml -o draft-ietf-gnap-core-protocol.xml
xml2rfc --html draft-ietf-gnap-core-protocol.xml
