FROM riggerthegeek/faas-node:latest

LABEL maintainer="Simon Emms <simon@simonemms.com>"

# COPY function node packages and install, adding this as a separate
# entry allows caching of npm install
ADD ./function ./function
ADD ./package*.json ./function/

RUN cd function \
  && npm install --production || :
