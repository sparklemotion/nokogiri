def java?
  /java/ === RUBY_PLATFORM
end

def add_file_to_gem(relative_source_path)
  dest_path = File.join(gem_build_path, relative_source_path)
  dest_dir = File.dirname(dest_path)

  mkdir_p dest_dir unless Dir.exist?(dest_dir)
  rm_f dest_path if File.exist?(dest_path)
  safe_ln relative_source_path, dest_path

  HOE.spec.files << relative_source_path
end

def gem_build_path
  File.join "pkg", HOE.spec.full_name
end
