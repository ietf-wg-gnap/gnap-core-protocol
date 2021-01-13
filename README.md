# Grant Negotiation and Authorization Protocol

![Latest Draft](https://img.shields.io/endpoint?url=https://a15hpmw3nd.execute-api.us-east-1.amazonaws.com/dev/draft_latest/draft-ietf-gnap-core-protocol)

This repository contains the core protocol specification of the
[Grant Negotiation and Authorization Protocol (GNAP) working group](https://datatracker.ietf.org/wg/gnap/about/)
of the Internet Engineering Task Force (IETF). All contributions
are subject to the [IETF Note Well](https://www.ietf.org/about/note-well/). 

Official working group drafts of this document are published at <https://datatracker.ietf.org/doc/draft-ietf-gnap-core-protocol/>.

A rendered version of the editors' copy (reflecting the current state of this repository) is available at <https://gnap-core-protocol-editors-draft.netlify.app/>. 

Discussion takes place on the [IETF GNAP mailing list (txauth)](https://www.ietf.org/mailman/listinfo/txauth).

## Building Instructions

This document is written using the `kramdown-rfc2629` variant of Markdown. To build using the included Docker image,
run the command:

```
docker-compose up
```

If successful, this will create the `xml`, `txt`, and `html` versions of the document in the `publish` directory.

To build the draft without Docker, install the `kramdown-rfc2629` and `xml2rfc` tools locally and run them directly 
or by using the simple `build.sh` script provided.
