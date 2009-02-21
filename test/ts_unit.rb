$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "test")

require "test/unit"

class Test::Unit::TestCase

  def self.method_added(sym)
    raise "#{sym} already defined!" if my_tests.include? sym
    my_tests_add sym
  end

  def self.my_tests_add(test)
    @my_tests << test
  end

  def self.my_tests
    @my_tests ||= []
  end

end


require "tc_page_xml_parsing"
require "tc_page"
require "tc_repository"
require "tc_wiki_text"
require "tc_string_aggregator"
require "tc_repository_parser"

