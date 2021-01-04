require "concourse"

Concourse.new("nokogiri", fly_target: "ci", format: true) do |c|
  c.add_pipeline "nokogiri", "nokogiri.yml", ytt: true
  c.add_pipeline "nokogiri-pr", "nokogiri-pr.yml", ytt: true
  c.add_pipeline "nokogiri-truffleruby", "nokogiri-truffleruby.yml", ytt: true
end
