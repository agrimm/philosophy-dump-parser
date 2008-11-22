require "rubygems"
require "xml"
require "page"

class PageXmlParser
  def initialize(page_xml_file)
    @page_xml_file = page_xml_file
  end

  def mainspace_pages
    xml = XML::Document.string(@page_xml_file.read)
    pages = []

    xml.root.find("*[local-name()='page']").each do |page_element|
      title, text = nil, nil

      page_element.find("*[local-name()='title']").each do |title_element|
        title = title_element.content
      end

      page_element.find("*/*[local-name()='text']").each do |text_element|
        text = text_element.content
      end

      page = Page.new_if_valid(title, text)
      pages << page unless page.nil?
    end
    return pages
  end
end

