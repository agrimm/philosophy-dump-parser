require "yaml"
require "page"
require "repository"
require "rubygems"
require "xml"

class XmlHandler
  def parse_next_page_details
    title, text = nil, nil

    raise if @finished

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

class ManuallyMadePageXmlParser
  def initialize(page_xml_file, tasklist_filename = nil)
    @page_xml_file = page_xml_file
    @tasks = TaskList.new(tasklist_filename)
    @repository = Repository.new
  end

  def parse_next_page(xml_handler, title_hash)
    result = nil
    while (parse_result = xml_handler.parse_next_page_details)
      title, text = parse_result[:title], parse_result[:text]
      result = @repository.new_page_if_valid(title, text, title_hash)
      break unless result.nil?
    end
    result
  end

  def parse_pages(xml_handler, title_hash)
    pages = []
    while (page = parse_next_page(xml_handler, title_hash))
      pages << page
    end
    pages
  end

  def parse_next_valid_title(xml_handler)
    result = nil
    while (parse_result = xml_handler.parse_next_page_details)
      result = parse_result[:title] if @repository.page_title_valid?(parse_result[:title])
      break unless result.nil?
    end
    result
  end

  def parse_pages_for_titles(xml_handler)
    titles = []
    while (title = parse_next_valid_title(xml_handler))
      titles << title
    end
    titles
  end

  def create_dumps
    title_hash = load_title_hash
    xml_handler = XmlHandler.new(@page_xml_file)
    subfile_number = 1
    max_pages_per_dump = 10000 #Can be anything
    pages = []
    while (page = parse_next_page(xml_handler, title_hash))
      pages << page
      if pages.size == max_pages_per_dump
        create_page_dump(pages, subfile_number)
        subfile_number += 1
        pages = []
      end
    end
    create_page_dump(pages, subfile_number)
  end

  def create_page_dump(pages, subfile_number)
    dump = Marshal.dump(pages)
    File.open("dumpfile#{subfile_number}.bin", "w") do |f|
      f.write(dump)
    end
  end

  def load_dumps
    pages = []
    each_dumpfilename do |filename|
      File.open(filename) do |f|
        pages.concat(Marshal.load(f))
      end
    end
    debug_mode = false
    if debug_mode
      actual_title_list = pages.map{|p| p.title}
      check = determine_title_list
      raise "pages minus check is #{(actual_title_list-check).inspect}" unless actual_title_list - check == []
      raise "check minus actual title list is #{(check - actual_title_list).inspect}" unless check - actual_title_list == []
    end
    pages
  end

  def delete_intermediate_files
    delete_dumpfiles
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
    xml_handler = XmlHandler.new(@page_xml_file)
    title_list = parse_pages_for_titles(xml_handler)
    title_list
  end

  def dump_title_list(title_list)
    File.open("temp/title_list.bin", "w") do |f|
      Marshal.dump(title_list, f)
    end
  end

  def build_title_list
    title_list = determine_title_list
    dump_title_list(title_list)
  end

  def load_title_hash
    title_list = nil
    File.open("temp/title_list.bin") do |f|
      title_list = Marshal.load(f)
    end
    title_hash = {}
    title_list.each {|title| title_hash[title] = true}
    title_hash
  end

  def mainspace_pages
    pages = []
    delete_intermediate_files if @tasks.first_possible_task_listed?
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
    possible_tasks = [:build_title_list, :create_dumps, :build_links]
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

  def first_listed_task
    first_listed_task = @tasks.min {|task1, task2| possible_tasks.index(task1) <=> possible_tasks.index(task2)}
  end

  def first_possible_task_listed?
    first_listed_task == possible_tasks.first
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

