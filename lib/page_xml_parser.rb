require 'rexml/document'

require "page"

class PageXmlParser
  def initialize(page_xml_file)
    @page_xml_file = page_xml_file
  end

  def mainspace_pages
    xml = REXML::Document.new(@page_xml_file)
    pages = []

    #To do: replace these hard-wired numbers
    2.upto(xml.root.elements.size) do |i|
      page_element = xml.root.elements[i]
      title_element = page_element.elements[1]
      title = title_element.text

      j = page_element.elements.size
      revision_element = page_element.elements[j]
      k = revision_element.elements.size
      text_element = revision_element.elements[k]
      text = text_element.text

      page = Page.new_if_valid(title, text)
      pages << page unless page.nil?
    end
    return pages
  end
end

