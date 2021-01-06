#!/usr/bin/python3

import urllib.request, json 
import os

print(os.environ)

urlbase = 'https://api.github.com/repos/jricher/gnap-core-protocol/actions/artifacts'

with urllib.request.urlopen(urlbase) as url:
    data = json.loads(url.read().decode())
    print(data)