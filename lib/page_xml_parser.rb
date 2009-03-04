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
  def initialize(page_xml_file, options, tasklist_filename = nil)
    @page_xml_file = page_xml_file
    @tasks = TaskList.new(tasklist_filename)
    @repository = Repository.new()
  end

  def parse_next_page(xml_handler)
    result = nil
    while (parse_result = xml_handler.parse_next_page_details)
      title, page_id, text = parse_result[:title], parse_result[:page_id], parse_result[:text]
      result = @repository.new_page_if_valid(title, page_id, text)
      break unless result.nil?
    end
    result
  end

  def parse_next_valid_page_details(xml_handler)
    result = nil
    while (parse_result = xml_handler.parse_next_page_details)
      result = parse_result if @repository.page_title_valid?(parse_result[:title])
      break unless result.nil?
    end
    result
  end

  def parse_pages_for_titles(xml_handler)
    while page = parse_next_page(xml_handler) do end
  end

  def add_text_to_pages
    xml_handler = XmlHandler.new(@page_xml_file)
    while details = parse_next_valid_page_details(xml_handler)
      page = Page.find_by_title(details[:title])
      page.add_text(details[:text])
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
    build_title_list if @tasks.include_task?(:build_title_list)
    add_text_to_pages if @tasks.include_task?(:create_dumps) #Task list may become obsolete soon, so don't change the internals
    build_links if @tasks.include_task?(:build_links)
    @tasks.write_next_tasks
    STDERR.puts(@tasks.status_report_string) unless @tasks.last_possible_task_completed?
  end

  def mainspace_pages
    do_analysis
    pages = @repository.pages
    pages
    #nil
  end

  def repository
    do_analysis #To do: make sure that calling repository multiple times doesn't re-run it
    @repository
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

