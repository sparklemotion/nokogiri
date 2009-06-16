module TestFiles
  Dir.chdir(File.dirname(__FILE__)) do
    Dir['files/*.{html,xhtml,xml}'].each do |fname|
      if RUBY_VERSION >= '1.9'
        const_set fname[%r!/(\w+)\.\w+$!, 1].upcase, File.open(fname, 'r:ascii-8bit') { |f| f.read }
      else
        const_set fname[%r!/(\w+)\.\w+$!, 1].upcase, File.read(fname)
      end
    end
  end
end
