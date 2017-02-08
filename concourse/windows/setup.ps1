. "concourse\windows\common.ps1"

$rubydk_path = join-path $installation_dir "rubydk"
$rubydk_config = join-path $rubydk_path "config.yml"
$rubydk_bin = join-path $rubydk_path "bin"
$rubydk_echo = join-path $rubydk_bin "echo.exe"

$rubyinstaller_url = "https://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.3.3-x64.exe"
$devkit_url = "https://dl.bintray.com/oneclick/rubyinstaller/DevKit-mingw64-64-4.7.2-20130224-1432-sfx.exe"

function is-ruby-23-installed {
    if (-not (test-path $ruby23_exe)) {
        return $FALSE
    }

    $p = start-cmd $ruby23_exe "--version"
    return (($p.exitcode -eq 0) -and ((get-content stdout.log) -match "ruby 2.3"))
}

function ensure-ruby-23-is-installed {
    write-host "checking if ruby 2.3 is already installed ..."
    if (is-ruby-23-installed) {
        write-host "ruby 2.3 is already installed"
        return
    }

    write-host "downloading ruby installer ..."
    invoke-webrequest $rubyinstaller_url -outfile "rubyinstaller.exe" -verbose

    write-host "running ruby installer ..."
    $p = start-process "rubyinstaller.exe" "/verysilent /dir=$($ruby23_path)" -wait -passthru
    if ($p.exitcode -ne 0) {
        throw "rubyinstaller returned error code: $($p.exitcode)"
    }

    write-host "checking if ruby 2.3 is properly installed ..."
    if (-not (is-ruby-23-installed)) {
        throw "ruby 2.3 was not properly installed"
    }
    write-host "ruby 2.3 has been installed"
}

function clean-ruby-23 {
    write-host "removing ruby 2.3 from the system ..."
    remove-item $ruby23_path -recurse -force
    if (is-ruby-23-installed) {
        throw "did not uninstall ruby 2.3 properly"
    }
}

function is-ruby-dk-extracted {
    if (-not (test-path $rubydk_path)) {
        return $FALSE
    }
    if (-not (test-path $rubydk_echo)) {
        return $FALSE
    }
    return $TRUE
}

function is-ruby-dk-installed {
    if (-not (is-ruby-dk-extracted)) {
        return $FALSE
    }

    $p = start-cmd $ruby23_exe "-rdevkit -e'puts 12345678'"
    return (($p.exitcode -eq 0) -and ((get-content stdout.log) -match "12345678"))
}

function ensure-ruby-dk-is-installed {
    $savedir = get-location

    write-host "checking if ruby dk is already installed ..."
    if (is-ruby-dk-installed) {
        write-host "ruby dk is already installed"
        return
    }

    if (-not (is-ruby-dk-extracted)) {
        write-host "creating dk install directory $($rubydk_path) ..."
        new-item -itemtype directory -force -path $rubydk_path

        set-location $rubydk_path

        write-host "downloading dk installer ..."
        invoke-webrequest $devkit_url -outfile "devkitinstaller.exe" -verbose

        write-host "running dk installer ..."
        $p = start-process "devkitinstaller.exe" "-y" -wait -passthru
        if ($p.exitcode -ne 0) {
            throw "devkitinstaller returned error code: $($p.exitcode)"
        }

        set-location $savedir
    }
    if (-not (is-ruby-dk-extracted)) {
        throw "ruby dk was not properly extracted"
    }
    write-host "ruby dk was properly extracted"

    if (-not (is-ruby-dk-installed)) {
        write-host "installing ruby dk ..."

        set-location $rubydk_path

        "---`n- $($ruby23_path)" | out-file $rubydk_config -encoding ASCII
        get-content $rubydk_config

        run-cmd $ruby23_exe "dk.rb install --force"

        set-location $savedir
    }
    if (-not (is-ruby-dk-installed)) {
        throw "ruby dk was not properly installed"
    }
    write-host "ruby dk has been installed"
}

function clean-ruby-dk {
    write-host "removing ruby dk from the system ..."
    remove-item $rubydk_path -recurse -force
    if (is-ruby-dk-installed) {
        throw "did not uninstall ruby dk properly"
    }
}

ensure-ruby-23-is-installed
ensure-ruby-dk-is-installed
