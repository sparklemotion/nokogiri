In order to set up this in a build mechanism a Dockerfile has been provided to create this, and would allow for bind-mount of a genuine build key at:

  /home/nokogiri/.abuild/xxxx.rsa /.rsa.pub

Run from root of repository

   docker build -f packages/alpine/Dockerfile -t alpine-nokogiri .

much of this taken from:

https://wiki.alpinelinux.org/wiki/Creating_an_Alpine_package

In order to publish, the APK and patch files here should be sent as a PR to alipe, so to get this into a publised state, the build process should be just update this file and do a PR?
