require "concourse"

Concourse.new("nokogiri", fly_target: "ci") do |c|
  c.add_pipeline "nokogiri", "nokogiri.yml"
  c.add_pipeline "nokogiri-pr", "nokogiri-pr.yml"
  c.add_pipeline "nokogiri-v1.10.x", "nokogiri-v1.10.x.yml"
end
