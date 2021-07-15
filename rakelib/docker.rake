#
# docker docker docker
#
namespace "docker" do
  IMAGE_DIR = "oci-images/nokogiri-test"
  RUBIES = {
    :mri=>["2.5", "2.6", "2.7", "3.0"],
    :truffle=>["nightly"],
  }

  def docker_tag_for(engine, version = nil)
    [engine, version].compact.join("-")
  end

  def docker_file_for(engine, version = nil)
    File.join(IMAGE_DIR, "Dockerfile.#{docker_tag_for(engine, version)}.generated")
  end

  def docker_image_for(engine, version = nil)
    "flavorjones/nokogiri-test:#{docker_tag_for(engine, version)}"
  end

  def docker_files_each
    Dir[File.join(IMAGE_DIR, "Dockerfile.*.erb")].each do |template_path|
      tag_or_engine = File.basename(template_path).gsub(/Dockerfile\.(.*)\.erb/, '\1').to_sym
      if RUBIES.keys.include?(tag_or_engine)
        # engine
        RUBIES[tag_or_engine].each do |version|
          dockerfile_path = docker_file_for(tag_or_engine, version)
          yield File.read(template_path), dockerfile_path, version, docker_image_for(tag_or_engine, version)
        end
      else
        # tag
        dockerfile_path = docker_file_for(tag_or_engine)
        yield File.read(template_path), dockerfile_path, nil, docker_image_for(tag_or_engine)
      end
    end
  end

  desc "Generate Dockerfiles"
  task "generate" do
    require "erb"
    docker_files_each do |template, dockerfile_path, version, _|
      puts "writing #{dockerfile_path} ..."
      File.open(dockerfile_path, "w") do |dockerfile|
        Dir.chdir(File.dirname(dockerfile_path)) do
          dockerfile.write ERB.new(template, nil, "%-").result(binding)
        end
      end
    end
  end

  desc "Build docker images for testing"
  task "build" do
    docker_files_each do |_, dockerfile_path, _, docker_image|
      sh "docker build -t #{docker_image} -f #{dockerfile_path} ."
    end
  end

  desc "Push a docker image for testing"
  task "push" do
    docker_files_each do |_, _, _, docker_image|
      sh "docker push #{docker_image}"
    end
  end

  desc "Pull upstream docker images"
  task "pull" do
    docker_files_each do |_, dockerfile_path, _, _|
      upstream = File.read(dockerfile_path).lines.grep(/FROM/).first.split("FROM ").last
      sh "docker pull #{upstream}"
    end
  end

  desc "Clean generated dockerfiles"
  task "clean" do
    generated_files = Dir[File.join(IMAGE_DIR, "Dockerfile.*.generated")]
    FileUtils.rm_f generated_files, verbose: true unless generated_files.empty?
  end
end

desc "Build and push a docker image for testing"
task "docker" => ["docker:generate", "docker:pull", "docker:build", "docker:push"]

CLEAN.add("oci-images/nokogiri-test/*.generated")
