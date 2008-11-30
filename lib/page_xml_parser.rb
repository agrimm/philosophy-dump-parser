require "rubygems"
require "xml"
require "page"

  if false
class LibXmlDocumentPageXmlParser
  def initialize(page_xml_file)
    @page_xml_file = page_xml_file
  end

  def mainspace_pages
    xml = XML::Document.string(@page_xml_file.read)
    pages = []

    xml.root.find("*").each do |page_element|
      next if page_element.name == "siteinfo"
      title, text = nil, nil
      page_element.find("*").each do |page_element_child|
        if page_element_child.name == "title"
          title_element = page_element_child
          title = String(title_element.content)
        elsif page_element_child.name == "revision"
          revision_element = page_element_child
          revision_element.find("*").each do |revision_element_child|
            next unless revision_element_child.name == "text"
            text_element = revision_element_child
            text = String(text_element.content)
          end
        end
      end
      raise if title.nil? or text.nil?
      page = Page.new_if_valid(title, text)
      pages << page unless page.nil?
    end

    Page.build_links(pages)
    return pages
  end
end
  end

class LibXmlReaderPageXmlParser
  def initialize(page_xml_file)
    @page_xml_file = page_xml_file
  end

  def mainspace_pages
    parser = XML::Reader.io(@page_xml_file)
    pages = []
    while (parser.read and not (parser.node_type == XML::Reader::TYPE_END_ELEMENT and parser.name == "mediawiki"))
      if (parser.node_type == XML::Reader::TYPE_ELEMENT and parser.name == "title")
        parser.read
        title = parser.value
      elsif (parser.node_type == XML::Reader::TYPE_ELEMENT and parser.name == "text")
        parser.read
        text = parser.value
        page = Page.new_if_valid(title, text)
        pages << page unless page.nil?
      end
    end
    Page.build_links(pages)
    return pages
  end

end

PageXmlParser = LibXmlReaderPageXmlParser

