# nokogiri concourse to-do

## concourse.yml

* [x] real ssl cert
* [x] github authentication
* [x] bastion host
* [x] upgrade bbl

## nokogiri.yml

* [x] test using system libraries
* [x] handle pull requests
* [x] run windows tests under devkit
* [ ] osx
  * system
  * system-homebrew
  * vendored
* [ ] build an rc gem and upload to rubygems [→ rubygems resource]
  * should always check manifest
* install gem and test:
  * [ ] osx
  * [ ] linux (system)
  * [ ] linux (vendored)
  * [ ] linux (vendored, --disable-static)
  * [ ] OpenSuse with site_config (lib64, #1562)
  * [ ] windows (fat binary)
  * [ ] windows (devkit)
* notifications on failure / success
  * [x] irc [→ irc resource]

## other projects

* [x] pipeline: mini_portile [→ bosh release]
* [x] pipeline: chromedriver-helper
* [x] bosh release for windows worker config:
  * [ ] ruby of all supported versions
  * [ ] devkit installed in all rubies
  * [ ] cmake
* [x] resource: irc
* [ ] resource: rubygems

## nokogiri stretch goals

* [ ] get openbsd / freebsd / etc. people to donate worker machines
* [ ] use an S3 bucket for sub-artifacts:
  * source tarballs
  * compiled .dlls
