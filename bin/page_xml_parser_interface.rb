#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "page_xml_parser"
require "page"

class ProcessXmlFile

  def main_method(filenames)
    filenames.each do |filename|
      puts "#{filename}\n\n"
      File.open(filename) do |xml_file|
        page_xml_parser = PageXmlParser.new(xml_file)
        mainspace_pages = page_xml_parser.mainspace_pages
        Page.analysis_output(mainspace_pages)
      end
    end
  end

end

if $0 == __FILE__
  ProcessXmlFile.new.main_method(ARGV)
end

