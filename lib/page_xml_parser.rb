require "rubygems"
require "page"

class ManuallyMadePageXmlParser
  def initialize(page_xml_file)
    @page_xml_file = page_xml_file
  end

  def mainspace_pages
    i = 0
    pages = []
    title, text_lines = nil, []
    end_of_page_text_found = false
    #big_string = "a" * 100000
    while line = @page_xml_file.gets
      if match_data = /<title>(.*)<\/title>/.match(line)
        title = exorcise_ampersands(match_data[1])
      else
        if match_data = /<text[^>]*>(.*)<\/text>/.match(line)
          text_lines << exorcise_ampersands(match_data[1])
          end_of_page_text_found = true
        elsif match_data = /<text[^>]*>(.*)$/m.match(line)
          text_lines << exorcise_ampersands(match_data[1])
        elsif match_data = /(.*)<\/text>/.match(line)
          text_lines << exorcise_ampersands(match_data[1])
          end_of_page_text_found = true
        elsif (text_lines.size > 0)
          text_lines << exorcise_ampersands(line)
        end

        if end_of_page_text_found
          text = text_lines.join
          i += 1
          page = Page.new_if_valid(title, text)
          pages << page unless page.nil?
          title, text_lines = nil, []
          end_of_page_text_found = false
          STDERR <<  "#{i}\t#{Time.now}\n" if (i % 10000 == 0)
          #GC.start if (i % 100000 == 0)
        end
      end
    end
    #STDERR << "Finished parsing"
    Page.build_links(pages)
    #STDERR << "Built links"
    pages
  end

  def exorcise_ampersands(string)
    #Handle amp and quot, which is required, and less than and greater than, because unit tests already existed for that.
    string.gsub!("&lt;", "<")
    string.gsub!("&gt;", ">")
    string.gsub!("&quot;", "\"")
    string.gsub!("&amp;", "&")
    string
  end

end

PageXmlParser = ManuallyMadePageXmlParser

