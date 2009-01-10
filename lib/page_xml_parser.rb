require "rubygems"
require "page"

class ManuallyMadePageXmlParser
  def initialize(page_xml_file)
    @page_xml_file = page_xml_file
  end

  def parse_pages(file)
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
          page = Page.new_if_valid(title, text)
          pages << page unless page.nil?
          title, text_lines = nil, []
          end_of_page_text_found = false
        end
      end
    end
    pages
  end

  def break_into_subfiles(original_file)
    subfile_number = 1
    pages_so_far = 0
    max_pages_per_file = 1
    subfile = File.open("temp/subfile#{subfile_number}.almostxml", "w")
    while line = original_file.gets
      subfile.write(line)
      if line.include?("</page>")
        pages_so_far += 1
        if (pages_so_far % max_pages_per_file == 0)
          subfile_number += 1
          pages_so_far = 0
          subfile.close
          subfile = File.open("temp/subfile#{subfile_number}.almostxml", "w")
        end
      end
    end
    subfile.close
  end

  def create_dump_given_subfile_number(subfile_number)
    return unless File.exist?("temp/subfile#{subfile_number}.almostxml")

    File.open("temp/subfile#{subfile_number}.almostxml") do |almost_xml_file|
      pages = parse_pages(almost_xml_file)
      dump = Marshal.dump(pages)
      File.open("dumpfile#{subfile_number}.bin", "w") do |f|
        f.write(dump)
      end
    end
  end

  def create_dumps
    break_into_subfiles(@page_xml_file)
    @page_xml_file.close
    1.upto(1000) do |subfile_number|
      result = create_dump_given_subfile_number(subfile_number)
    end
  end

  def load_dumps
    pages = []
    each_dumpfilename do |filename|
      File.open(filename) do |f|
        dump = f.read
        pages += Marshal.load(dump)
      end
    end
    pages
  end

  def delete_intermediate_files
    delete_dumpfiles
    delete_almost_xml_subfiles
  end

  def each_dumpfilename
    i = 0
    while (i += 1)
      filename = "dumpfile#{i}.bin"
      break unless File.exist?(filename)
      yield filename if block_given?
    end
  end

  def delete_dumpfiles
    each_dumpfilename do |filename|
      File.delete(filename)
    end
  end

  def each_almost_xml_subfilename
    i = 0
    while (i += 1)
      filename = "temp/subfile#{i}.almostxml"
      break unless File.exist?(filename)
      yield filename if block_given?
    end
  end

  def delete_almost_xml_subfiles
    each_almost_xml_subfilename do |filename|
      File.delete(filename)
    end
  end

  def mainspace_pages
    delete_intermediate_files
    create_dumps
    pages = load_dumps
    Page.build_links(pages)
    delete_intermediate_files
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

