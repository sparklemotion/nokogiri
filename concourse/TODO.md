# nokogiri concourse to-do

## concourse.yml

* [x] real ssl cert
* [x] github authentication
* [ ] pipeline: update stemcell(s)
* [ ] bastion host
* [ ] pipeline: repave bastion host
* [ ] ¿upgrade bbl?
* [ ] ¿stackdriver bosh release?

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
  * [ ] ¿use a task.yml?
  * [ ] irc [→ irc resource]
  * [ ] email (using existing resource)

## other projects

* [x] pipeline: mini_portile [→ bosh release]
* [x] pipeline: chromedriver-helper
* [ ] pipeline: LicenseFinder
  * [ ] and PR a windows task back to the project
* [ ] move to AWS S3 for the bosh release blobstore (because bosh.io)
* [x] bosh release for windows worker config:
  * [ ] ruby of all supported versions
  * [ ] devkit installed in all rubies
  * [ ] cmake
* [ ] resource: irc
* [ ] resource: rubygems

## nokogiri stretch goals

* [ ] get openbsd / freebsd / etc. people to donate worker machines
* [ ] use an S3 bucket for sub-artifacts:
  * source tarballs
  * compiled .dlls
