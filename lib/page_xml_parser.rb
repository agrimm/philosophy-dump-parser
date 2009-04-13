$PAGE_XML_PARSER_DEBUG_MODE = false

require "yaml"
require "page"
require "repository"
require "rubygems"
require "xml"

class XmlHandler
  def read_and_get_value
    @xml_parser.read
    return @xml_parser.value
  end

  def node_name_is?(name)
    return (@xml_parser.node_type == XML::Reader::TYPE_ELEMENT and @xml_parser.name == name)
  end

  def parse_next_page_details
    title, page_id, text = nil, nil, nil

    raise if @finished

    while (read_result = @xml_parser.read and not (@xml_parser.node_type == XML::Reader::TYPE_END_ELEMENT and @xml_parser.name == "mediawiki"))
      raise if read_result == -1
      if node_name_is?("title")
        title = read_and_get_value
      elsif (node_name_is?("id") and page_id == nil)
        page_id_string = read_and_get_value
        raise if page_id_string[0..0] == "0"
        page_id = Integer(page_id_string)
      elsif node_name_is?("text")
        text = read_and_get_value
        return {:title => title, :page_id => page_id, :text => text}
      end
    end
    set_finished
    return nil
  end

  def set_finished
    @xml_file.rewind
    @finished = true
  end

  def initialize(xml_file)
    @xml_file = xml_file
    @xml_parser = XML::Reader.io(@xml_file)
    @finished = false
  end

end

class PageXmlParser
  def initialize(page_xml_file, options)
    @page_xml_file = page_xml_file
    @repository = Repository.new_with_configuration(options)
  end

  def parse_pages_for_titles(xml_handler)
    @repository.within_transactions(nil) do
      while (parse_result = xml_handler.parse_next_page_details)
        title, page_id = parse_result[:title], parse_result[:page_id]
        @repository.new_page_if_valid(title, page_id)
      end
    end
  end

  def parse_next_valid_page_details(xml_handler)
    result = nil
    while (parse_result = xml_handler.parse_next_page_details)
      result = parse_result if @repository.page_title_valid?(parse_result[:title])
      break unless result.nil?
    end
    result
  end

  def add_text_to_pages
    xml_handler = XmlHandler.new(@page_xml_file)
    @repository.within_transactions(100000) do
      while details = parse_next_valid_page_details(xml_handler)
        @repository.add_to_page_by_title_some_text(details[:title], details[:text])
      end
    end
  end

  def build_links
    @repository.build_total_backlink_counts
  end

  def build_title_list
    xml_handler = XmlHandler.new(@page_xml_file)
    parse_pages_for_titles(xml_handler)
  end

  def do_analysis
    STDERR.puts "about to build title list at #{Time.now}" if $PAGE_XML_PARSER_DEBUG_MODE
    build_title_list
    STDERR.puts "about to add text to pages at #{Time.now}" if $PAGE_XML_PARSER_DEBUG_MODE
    add_text_to_pages
    STDERR.puts "about to build links at #{Time.now}" if $PAGE_XML_PARSER_DEBUG_MODE
    build_links
    STDERR.puts "built links at #{Time.now}" if $PAGE_XML_PARSER_DEBUG_MODE
  end

  def repository
    do_analysis #To do: make sure that calling repository multiple times doesn't re-run it
    @repository
  end
end

