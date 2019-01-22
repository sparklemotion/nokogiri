#
# docker docker docker
#
namespace "docker" do
  image_dir = "concourse/images"
  supported_engines = [:mri, :jruby] # keys in Concourse::RUBIES

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
      supported_engines.each do |engine|
        Concourse::RUBIES[engine].each do |version|
          File.open(docker_file_for(engine, version), "w") do |dockerfile|
            puts "writing #{dockerfile.path} ..."
            dockerfile.write ERB.new(File.read("Dockerfile.#{engine}.erb"), nil, "%-").result(binding)
          end
        end
      end
    end
  end

  desc "Build docker images for testing"
  task "build" do
    supported_engines.each do |engine|
      Concourse::RUBIES[engine].each do |version|
        sh "docker build -t #{docker_image_for(engine, version)} -f #{image_dir}/#{docker_file_for(engine, version)} ."
      end
    end
  end

  desc "Push a docker image for testing"
  task "push" do
    supported_engines.each do |engine|
      Concourse::RUBIES[engine].each do |version|
        sh "docker push #{docker_image_for(engine, version)}"
      end
    end
  end
end

desc "Build and push a docker image for testing"
task "docker" => ["docker:generate", "docker:build", "docker:push"]
