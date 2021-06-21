# frozen_string_literal: true
require "helper"

class Nokogiri::TestCase
  describe Nokogiri::HTML do
    it "is the same as Nokogiri::HTML4" do
      assert_same(Nokogiri::HTML, Nokogiri::HTML4)
    end
  end

  describe "Nokogiri.HTML()" do
    it "is the same as Nokogiri.HTML4()" do
      assert_equal(Nokogiri.method(:HTML), Nokogiri.method(:HTML4))
    end
  end
end
