require "rubygems"
require "page"

class ManuallyMadePageXmlParser
  def initialize(page_xml_file)
    @page_xml_file = page_xml_file
  end

  def parse_pages(file)
    i = 0
    pages = []
    title, text_lines = nil, []
    end_of_page_text_found = false
    while line = file.gets
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
          #STDERR <<  "#{i}\t#{Time.now}\n" if (i % 10000 == 0)
          #GC.start if (i % 100000 == 0)
        end
      end
    end
    pages
  end

  def create_dump
    pages = parse_pages(@page_xml_file)
    dump = Marshal.dump(pages)
    File.open("dumpfile.bin", "w") do |f|
      f.write(dump)
    end
  end

  def load_dump
    pages = nil
    File.open("dumpfile.bin") do |f|
      dump = f.read
      pages = Marshal.load(dump)
    end
    pages
  end

  def mainspace_pages
    create_dump
    pages = load_dump
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

