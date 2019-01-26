FROM alpine:latest

RUN apk update && apk upgrade
RUN apk add build-base
RUN apk add alpine-sdk shadow
RUN adduser -D -G abuild -s /bin/sh nokogiri
RUN echo "nokogiri ALL=(ALL) ALL" >> /etc/sudoers

USER nokogiri
ADD --chown=nokogiri:abuild . /build/
ADD --chown=nokogiri:abuild patches/libxml2/*.patch /build/packages/alpine/
WORKDIR /build/packages/alpine/

RUN abuild-keygen -a

RUN abuild -R
