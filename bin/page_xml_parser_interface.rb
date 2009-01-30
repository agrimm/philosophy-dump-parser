#!/usr/bin/env ruby

# == Synopsis
#
# Parse Wikipedia dumps for the "Get to Philosophy" game.
# Start at a random article, click on the first link within the article.
# Keep on doing that, and you may end up at Philosophy. What's up with that?
#
# == Usage
#
# bin/page_xml_parser_interface.rb languagewiki-dumpdate-pages-articles.xml

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "page_xml_parser"
require "page"
require "repository"
require "rubygems"
require "rdoc/usage"

class ProcessXmlFile

  def main_method(filename)
    puts "#{filename}\n\n"
    File.open(filename) do |xml_file|
      page_xml_parser = PageXmlParser.new(xml_file, "tasks.yml")
      mainspace_pages = page_xml_parser.mainspace_pages
      next unless page_xml_parser.finished?
      repository = Repository.new(mainspace_pages)
      repository.analysis_output(STDOUT)
      puts
    end
  end

end

if $0 == __FILE__
  RDoc::usage("usage") unless ARGV.size == 1
  ProcessXmlFile.new.main_method(ARGV[0])
end

