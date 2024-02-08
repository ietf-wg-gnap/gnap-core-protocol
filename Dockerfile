FROM python:3-slim

# Install ruby

RUN apt-get update && \
  apt-get install -y \
     ruby \
     npm && \
  apt-get clean

# Install xml2rfc
RUN pip install xml2rfc

# Install kramdown-rfc2629
RUN gem install kramdown-rfc2629

# Install aa2svg
RUN npm install -g aasvg
