#!/usr/bin/env ruby

require "rubygems"
#require "bleak_house"

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "page_xml_parser"
require "page"
require "repository"

class ProcessXmlFile

  def main_method(filenames)
    filenames.each do |filename|
      puts "#{filename}\n\n"
      File.open(filename) do |xml_file|
        page_xml_parser = PageXmlParser.new(xml_file, "tasks.yml")
        mainspace_pages = page_xml_parser.mainspace_pages
        next unless page_xml_parser.finished?
        repository = Repository.new(mainspace_pages)
        puts repository.analysis_output_string
      end
    end
  end

end

if $0 == __FILE__
  ProcessXmlFile.new.main_method(ARGV)
end

