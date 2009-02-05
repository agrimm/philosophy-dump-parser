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

class ProcessXmlFile

  def load_configuration
    filename = "configuration.yml"
    unless File.exist?(filename)
      STDERR.puts "Configuration file #{filename} not found"
      STDERR.puts "Try copying configuration.example.yml" if File.exist?("configuration.example.yml")
      exit 1
    end
    configuration_options = YAML::load_file(filename)
    configuration_options
  end

  def main_method(filename)
    puts "#{filename}\n\n"
    File.open(filename) do |xml_file|
      page_xml_parser = PageXmlParser.new(xml_file, "tasks.yml")
      configuration = load_configuration
      mainspace_pages = page_xml_parser.mainspace_pages
      next unless page_xml_parser.finished?
      repository = Repository.new_with_configuration(mainspace_pages, configuration)
      repository.analysis_output(STDOUT)
      puts
    end
  end

end

if $0 == __FILE__
  unless ARGV.size == 1
    require "rdoc/usage"
    RDoc::usage("usage")
  end
  ProcessXmlFile.new.main_method(ARGV[0])
end

