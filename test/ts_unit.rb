$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "test")

require "tc_page_xml_parsing"
require "tc_page"
require "tc_repository"
require "tc_wiki_text"
require "tc_string_aggregator"

