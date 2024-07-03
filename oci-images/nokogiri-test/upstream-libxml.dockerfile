#
# intended for use in the libxml2 CI pipeline to test Nokogiri as a downstream consumer
#
FROM ruby:3.3

# include_file debian-prelude.step
# -*- dockerfile -*-

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y apt-utils

# include_file valgrind-from-source.step
# -*- dockerfile -*-

RUN apt-get install -y libc6-dbg
RUN wget https://sourceware.org/pub/valgrind/valgrind-3.21.0.tar.bz2 && \
    tar -xf valgrind-3.21.0.tar.bz2 && \
    cd valgrind-3.21.0 && \
    ./configure && \
    make && \
    make install


RUN apt-get install -y autogen libtool shtool

# include_file update-bundler.step
# -*- dockerfile -*-

RUN gem install bundler

# include_file bundle-install.step
# -*- dockerfile -*-

COPY Gemfile nokogiri/
COPY Gemfile.lock nokogiri/
COPY nokogiri.gemspec nokogiri/

RUN gem install bundler -v "$(grep -A 1 "BUNDLED WITH" nokogiri/Gemfile.lock | tail -n 1)"
RUN cd nokogiri && bundle install

