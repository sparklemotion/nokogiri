require 'mkmf'
$CFLAGS += ' -std=c99'

if have_library('xml2', 'xmlNewDoc')
  # libxml2 libraries from http://www.xmlsoft.org/
  pkg_config('libxml-2.0')

  # nokogiri configuration from gem install
  nokogiri_lib = Gem
                 .find_files('nokogiri')
                 .select { |name| name.match(%r{gems/nokogiri-([\d.]+)/lib/nokogiri}) }
                 .sort_by { |name| name[/nokogiri-([\d.]+)/, 1].split('.').map(&:to_i) }
                 .last
  if nokogiri_lib
    nokogiri_ext = nokogiri_lib.sub(%r{lib/nokogiri(.rb)?$}, 'ext/nokogiri')

    # if that doesn't work, try workarounds found in Nokogiri's extconf
    unless find_header('nokogiri.h', nokogiri_ext)
      require "#{nokogiri_ext}/extconf.rb"
    end

    # if found, enable direct calls to Nokogiri (and libxml2)
    $CFLAGS += ' -DNGLIB' if find_header('nokogiri.h', nokogiri_ext)

    # If libnokogiri is not on the build path, we need to add it.
    unless have_library('nokogiri', 'Nokogiri_wrap_xml_document')
      nokogiri_libfile = 'nokogiri.' + RbConfig::CONFIG['DLEXT']
      nokogiri_libpath = File.join(nokogiri_ext, nokogiri_libfile)
      if File.exist? nokogiri_libpath
        $LDFLAGS += " -Wl,-rpath #{nokogiri_ext} -L#{nokogiri_ext} "
        # GNU ld:
        # '-lFOO' => looks for a file named 'libFOO.a' or 'libFOO.so*'
        # '-l:FOO' => looks for a file named exactly 'FOO'
        # OSX/Mach ld:
        # - '-l:' is not supported.
        # - Only links '.dylib', not '.bundle'
        #
        # Nokogiri does NOT have a lib prefix, so we need to be creative in
        # testing; and might have either .dylib or .bundle suffixes.
        $LIBS += ' ' + nokogiri_libpath + ' ' \
          if %w(so dylib).include? RbConfig::CONFIG['DLEXT']
      else
        puts 'WARNING! Could not find Nokogiri_wrap_xml_document symbol; build might fail.'
      end
    end
  end
end

# add in gumbo-parser source from github if not already installed
unless have_library('gumbo', 'gumbo_parse')
  rakehome = ENV['RAKEHOME'] || File.expand_path('../..')
  unless File.exist? "#{rakehome}/ext/nokogumboc/gumbo.h"
    require 'fileutils'
    FileUtils.cp Dir["#{rakehome}/gumbo-parser/src/*"],
                 "#{rakehome}/ext/nokogumboc"

    case RbConfig::CONFIG['target_os']
    when 'mingw32', /mswin/
      FileUtils.cp Dir["#{rakehome}/gumbo-parser/visualc/include/*"],
                   "#{rakehome}/ext/nokogumboc"
    end

    $srcs = $objs = nil
  end
end

# We use some Gumbo Internals, and not all distros ship the internal headers.
header_typedefs = {
  'error.h' => 'GumboErrorType',
  'insertion_mode.h' => 'GumboInsertionMode',
  'parser.h' => 'GumboParser',
  'string_buffer.h' => 'GumboStringBuffer',
  'token_type.h' => 'GumboTokenType',
}

header_typedefs.each_pair do |header, type|
  unless find_type(type, header)
    require 'fileutils'
    FileUtils.cp Dir["#{rakehome}/gumbo-parser/src/#{header}"],
      "#{rakehome}/ext/nokogumboc"
  end
end

create_makefile('nokogumboc')
