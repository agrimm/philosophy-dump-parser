require 'rexml/document'

require "page"

class PageXmlParser
  def initialize(page_xml_file)
    @page_xml_file = page_xml_file
  end

  def mainspace_pages
    xml = REXML::Document.new(@page_xml_file)
    pages = []

    xml.elements.each("*/page") do |page_element|
      title_element = page_element.elements["title"]
      title = title_element.text

      text_element = page_element.elements["revision/text"]
      text = text_element.text

      page = Page.new_if_valid(title, text)
      pages << page unless page.nil?
    end
    return pages
  end
end

