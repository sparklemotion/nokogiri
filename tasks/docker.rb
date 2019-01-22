#
# docker docker docker
#
namespace "docker" do
  image_dir = "concourse/images"

  def docker_tag_for(engine, version)
    [engine, version].join("-")
  end

  def docker_file_for(engine, version)
    "Dockerfile.#{docker_tag_for(engine, version)}.generated"
  end

  def docker_image_for(engine, version)
    "flavorjones/nokogiri-test:#{docker_tag_for(engine, version)}"
  end

  desc "Generate Dockerfiles"
  task "generate" do
    Dir.chdir image_dir do
      Concourse::RUBIES[:mri].each do |ruby_version|
        File.open(docker_file_for("mri", ruby_version), "w") do |dockerfile|
          puts "writing #{dockerfile.path} ..."
          dockerfile.write ERB.new(File.read("Dockerfile.ruby.erb"), nil, "%-").result(binding)
        end
      end
    end
  end

  desc "Build docker images for testing"
  task "build" do
    Concourse::RUBIES[:mri].each do |ruby_version|
      sh "docker build -t #{docker_image_for("mri", ruby_version)} -f #{image_dir}/#{docker_file_for(:mri, ruby_version)} ."
    end
  end

  desc "Push a docker image for testing"
  task "push" do
    Concourse::RUBIES[:mri].each do |ruby_version|
      sh "docker push #{docker_image_for("mri", ruby_version)}"
    end
  end
end

desc "Build and push a docker image for testing"
task "docker" => ["docker:generate", "docker:build", "docker:push"]
