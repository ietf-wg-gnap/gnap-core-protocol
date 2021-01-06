#!/usr/bin/python

import urllib.request, json 

urlbase = 'https://api.github.com/repos/jricher/gnap-core-protocol/actions/artifacts'

with urllib.request.urlopen(urlbase) as url:
    data = json.loads(url.read().decode())
    print(data)