require 'mkmf'
$CFLAGS += " -std=c99"

$warnflags = CONFIG['warnflags'] = '-Wall'

if have_library('xml2', 'xmlNewDoc') 
  # libxml2 libraries from http://www.xmlsoft.org/
  pkg_config('libxml-2.0')

  # nokogiri configuration from gem install
  nokogiri_lib = Gem.find_files('nokogiri').
    select { |name| name.match(%r{gems/nokogiri-([\d.]+)/lib/nokogiri}) }.
    sort_by {|name| name[/nokogiri-([\d.]+)/,1].split('.').map(&:to_i)}.last
  if nokogiri_lib
    nokogiri_ext = nokogiri_lib.sub(%r(lib/nokogiri(.rb)?$), 'ext/nokogiri')

    # if that doesn't work, try workarounds found in Nokogiri's extconf
    unless find_header('nokogiri.h', nokogiri_ext)
      require "#{nokogiri_ext}/extconf.rb"
    end

    # if found, enable direct calls to Nokogiri (and libxml2)
    $CFLAGS += ' -DNGLIB' if find_header('nokogiri.h', nokogiri_ext)
  end
end

# Symlink gumbo-parser source files.
ext_dir = File.dirname(__FILE__)
unless File.exist?(File.join(ext_dir, "gumbo.h"))
  require 'fileutils'
  gumbo_dir = File.expand_path('../../gumbo-parser', ext_dir)
  FileUtils.ln_s(Dir[File.join(gumbo_dir, 'src/*.[hc]')], ext_dir, force:true)
  # Set these to nil so that create_makefile picks up the new sources.
  $srcs = $objs = nil
end

create_makefile('nokogumbo/nokogumbo')
# vim: set sw=2 sts=2 ts=8 et:
