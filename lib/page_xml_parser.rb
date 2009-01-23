require "yaml"
require "page"
require "rubygems"
require "xml"

class XmlHandler
  def parse_next_page_details
    title, text = nil, nil

    while (read_result = @xml_parser.read and not (@xml_parser.node_type == XML::Reader::TYPE_END_ELEMENT and @xml_parser.name == "mediawiki"))
      raise if read_result == -1
      if (@xml_parser.node_type == XML::Reader::TYPE_ELEMENT and @xml_parser.name == "title")
        @xml_parser.read
        title = @xml_parser.value
      elsif (@xml_parser.node_type == XML::Reader::TYPE_ELEMENT and @xml_parser.name == "text")
        @xml_parser.read
        text = @xml_parser.value
        return {:title => title, :text => text}
      end
    end
    return nil
  end

  def initialize(xml_file)
    @xml_parser = XML::Reader.io(xml_file)
  end

end

class ManuallyMadePageXmlParser
  def initialize(page_xml_file, tasklist_filename = nil)
    @page_xml_file = page_xml_file
    @tasks = TaskList.new(tasklist_filename)
  end

  def parse_pages(xml_handler, title_hash)
    pages = []
    while (parse_result = xml_handler.parse_next_page_details)
      title, text = parse_result[:title], parse_result[:text]
      page = Page.new_if_valid(title, text, title_hash)
      pages << page unless page.nil?
    end
    pages
  end

  def parse_pages_for_titles(xml_handler)
    titles = []
    while (parse_result = xml_handler.parse_next_page_details)
      title = parse_result[:title]
      titles << title if Page.title_valid?(title)
    end
    titles
  end

  def break_into_subfiles
    delete_intermediate_files
    subfile_number = 1
    pages_so_far = 0
    max_pages_per_file = 1000_000_000
    subfile = open_subfile(subfile_number, {:first=>true})
    while line = @page_xml_file.gets
      subfile.write(line)
      if line.include?("</page>")
        pages_so_far += 1
        if (pages_so_far % max_pages_per_file == 0)
          subfile_number += 1
          pages_so_far = 0
          close_subfile(subfile, {:last=>false})
          subfile = open_subfile(subfile_number, {:first=>false})
        end
      end
    end
    close_subfile(subfile, {:last=>true})
    @page_xml_file.close
  end

  def open_subfile(subfile_number, options)
    subfile = File.open("temp/subfile#{subfile_number}.almostxml", "w")
    first = options[:first]
    subfile << "<mediawiki>\n" unless first
    subfile
  end

  def close_subfile(subfile, options)
    last = options[:last]
    subfile << "</mediawiki>\n" unless last
    subfile.close
  end

  def create_dump_given_subfile_number(subfile_number, title_list)
    return unless File.exist?("temp/subfile#{subfile_number}.almostxml")

    File.open("temp/subfile#{subfile_number}.almostxml") do |almost_xml_file|
      xml_handler = XmlHandler.new(almost_xml_file)
      pages = parse_pages(xml_handler, title_list)
      dump = Marshal.dump(pages)
      File.open("dumpfile#{subfile_number}.bin", "w") do |f|
        f.write(dump)
      end
    end
  end

  def create_dumps
    title_hash = load_title_hash
    almost_xml_subfilenames.each_index do |i|
      subfile_number = i + 1
      result = create_dump_given_subfile_number(subfile_number, title_hash)
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
    actual_title_list = pages.map{|p| p.title}
    debug_mode = false
    if debug_mode
      check = determine_title_list
      raise "pages minus check is #{(actual_title_list-check).inspect}" unless actual_title_list - check == []
      raise "check minus actual title list is #{(check - actual_title_list).inspect}" unless check - actual_title_list == []
    end
    pages
  end

  def delete_intermediate_files
    delete_dumpfiles
    delete_almost_xml_subfiles
    delete_title_list
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

  def almost_xml_subfilenames
    result = []
    i = 0
    while (i += 1)
      filename = "temp/subfile#{i}.almostxml"
      break unless File.exist?(filename)
      result << filename
    end
    result
  end

  def delete_almost_xml_subfiles
    almost_xml_subfilenames.each do |filename|
      File.delete(filename)
    end
  end

  def delete_title_list
    filename = "temp/title_list.bin"
    File.delete(filename) if File.exist?(filename)
  end

  def build_links
    pages = load_dumps
    Page.build_links(pages)
    delete_intermediate_files
    pages
  end

  def determine_title_list
    title_list = []
    almost_xml_subfilenames.each do |filename|
      File.open(filename) do |f|
        xml_handler = XmlHandler.new(f)
        title_list += parse_pages_for_titles(xml_handler)
      end
    end
    title_list
  end

  def dump_title_list(title_list)
    dump = Marshal.dump(title_list)
    File.open("temp/title_list.bin", "w") do |f|
      f.write(dump)
    end
  end

  def build_title_list
    title_list = determine_title_list
    dump_title_list(title_list)
  end

  def load_title_hash
    title_list = nil
    File.open("temp/title_list.bin") do |f|
      dump = f.read
      title_list = Marshal.load(dump)
    end
    title_hash = {}
    title_list.each {|title| title_hash[title] = true}
    title_hash
  end

  def mainspace_pages
    pages = []
    break_into_subfiles if @tasks.include_task?(:break_into_subfiles)
    build_title_list if @tasks.include_task?(:build_title_list)
    create_dumps if @tasks.include_task?(:create_dumps)
    pages = build_links if @tasks.include_task?(:build_links)
    @tasks.write_next_tasks
    STDERR.puts(@tasks.status_report_string) unless @tasks.last_possible_task_completed?
    pages
  end

  def finished?
    @tasks.last_possible_task_completed?
  end

  def exorcise_ampersands(string)
    illegal_characters = ["<", ">", "\""] #Ampersand is slightly different
    illegal_characters.each {|c| raise if string.include?(c)}
    #Handle amp and quot, which is required, and less than and greater than, because unit tests already existed for that.
    string.gsub!("&lt;", "<")
    string.gsub!("&gt;", ">")
    string.gsub!("&quot;", "\"")
    string.gsub!("&amp;", "&")
    string
  end

end

class TaskList

  def initialize(filename)
    @filename = filename
    @tasks = get_tasks
  end

  def include_task?(task)
    @tasks.include?(task)
  end

  def possible_tasks
    possible_tasks = [:break_into_subfiles, :build_title_list, :create_dumps, :build_links]
  end

  def get_tasks
    tasks = []
    if ( !@filename.nil? and File.exist?(@filename))
      yml_data = YAML::load(File.read(@filename))
      raise "Error: no variables" unless yml_data
      tasks = yml_data[:tasks]
      raise "Error: no tasks" if tasks.empty?
      raise "Error: invalid task" unless (tasks - possible_tasks).empty?
    else
      tasks = possible_tasks
    end
    tasks
  end

  def write_next_tasks
    return if @filename.nil?

    begin
      File.open(@filename,"w") do |f|
        f.write({:tasks=>next_tasks}.to_yaml)
      end
    rescue
      STDERR << "Something went wrong when saving the next task. It's probably the hard drive's fault."
      raise
    end
  end

  def last_completed_task
    last_completed_task = @tasks.max {|task1, task2| possible_tasks.index(task1) <=> possible_tasks.index(task2)}
  end

  def last_possible_task_completed?
    last_completed_task == possible_tasks.last
  end

  def next_tasks
    if last_possible_task_completed?
      next_task = possible_tasks.first
    else
      next_task = possible_tasks[possible_tasks.index(last_completed_task) + 1]
    end
    results = [next_task]
    results
  end

  def status_report_string
    if last_possible_task_completed?
      "All tasks completed"
    else
      "#{@tasks.join(",")} completed, next tasks #{next_tasks.join(",")}"
    end
  end

end
PageXmlParser = ManuallyMadePageXmlParser

