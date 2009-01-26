$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.uniq!

require "test/unit"
require "page" #Current home of string aggregator

class TestStringAggregator < Test::Unit::TestCase
  #Verification test
  def test_avoid_side_effects
    string = "unmodified text"
    aggregator = StringAggregator.new(string) << "modifying text"
    assert_equal "unmodified text", string, "The original string is inadvertently modified."
  end
end

