namespace :docs do
  desc "generate HTML docs for nokogiri.org"
  task :website do
    title = "#{HOE.name}-#{HOE.version} Documentation"

    options = []
    options << "--main=#{HOE.readme_file}"
    options << '--format=activerecord'
    options << '--threads=1'
    options << "--title=#{title.inspect}"

    options += HOE.spec.require_paths
    options += HOE.spec.extra_rdoc_files
    require 'rdoc/rdoc'
    ENV['RAILS_ROOT'] ||= File.expand_path(File.join('..', 'nokogiri_ws'))
    RDoc::RDoc.new.document options
  end
end
