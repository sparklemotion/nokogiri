require "concourse"

Concourse.new("nokogiri", fly_target: "ci", format: true) do |c|
  c.add_pipeline "nokogiri", "nokogiri.yml"
  c.add_pipeline "nokogiri-pr", "nokogiri-pr.yml", ytt: true
end
