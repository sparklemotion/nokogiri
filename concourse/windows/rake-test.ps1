. "ci\concourse\windows\common.ps1"

prepend-path $ruby23_bin_path
$env:RUBYOPT = "-rdevkit"

push-location nokogiri

    stream-cmd "gem" "install bundler"
    stream-cmd "bundle" "install"
    stream-cmd "bundle" "exec rake test"

pop-location
