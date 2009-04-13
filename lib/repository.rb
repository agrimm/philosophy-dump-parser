$REPOSITORY_DEBUG_MODE = false

class Repository < ActiveRecord::Base

  has_many :pages

  def execute_sometime(statement)
    if @statements_to_be_executed.nil?
      raise "No request made to put statements into transactions: @statements_to_be_executed is #{@statements_to_be_executed.inspect}"
    else
      @statements_to_be_executed << statement
      STDERR.puts "Size of #{@statements_to_be_executed.size} at #{Time.now}" if @statements_to_be_executed.size.to_s =~ /^[125]000*$/ and $REPOSITORY_DEBUG_MODE
      commit_statements if @maximum_statements_allowed_in_queue and @statements_to_be_executed.size == @maximum_statements_allowed_in_queue
    end
  end

  def within_transactions(size)
    raise "Can't happen" unless @statements_to_be_executed.nil?
    @statements_to_be_executed = []
    @maximum_statements_allowed_in_queue = size
    yield
    commit_statements
    @statements_to_be_executed = nil
  end

  def commit_statements
    raise "Can't happen" if @statements_to_be_executed.nil?
    STDERR.puts "About to commit #{@statements_to_be_executed.size} statements at #{Time.now}" if $REPOSITORY_DEBUG_MODE
    begin
      ActiveRecord::Base.connection.execute "Begin"
      @statements_to_be_executed.each {|statement| ActiveRecord::Base.connection.execute statement}
    ensure
      ActiveRecord::Base.connection.execute "Commit"
    end
    STDERR.puts "Committed #{@statements_to_be_executed.size} statements at #{Time.now}" if $REPOSITORY_DEBUG_MODE
    @statements_to_be_executed = []
  end

  def new_page_if_valid(title, page_id)
    return unless page_parameters_valid?(title)
    raise if page_id < 1
    execute_sometime "insert into pages VALUES (null, '#{sql_fake_escape(title)}', #{page_id}, null, null, #{self.id})"
    return #Just to emphasize it doesn't return the page
  end

  def page_parameters_valid?(title)
    return false unless page_title_valid?(title) #Not heckle proof?
    return true
  end

  def page_title_valid?(title)
    raise TitleNilError if title.nil?
    return false if title =~ /:/
    raise "Invalid title #{title}" if title != upcase_first_letter(title)
    return true
  end

  def find_page_id_by_title(title)
    result = self.class.connection.select_one("select id from pages where title = '#{sql_fake_escape(title)}' and repository_id = #{self.id}")
    raise TitleNotFoundError if result.nil?
    result["id"]
  end

  def find_page_id_by_unupcased_title(title)
    begin
      return find_page_id_by_title(upcase_first_letter(title))
    rescue TitleNotFoundError
      return nil
    end
  end

  def upcase_first_letter(string)
    return string if string == ""
    return string[0..0].upcase + string[1..-1]
  end

  def add_to_page_by_title_some_text(title, text)
    page_id = find_page_id_by_title(title)
    wiki_text = WikiText.new(text)
    wiki_text.linked_articles.each do |potential_title|
      potential_link_id = find_page_id_by_unupcased_title(potential_title)
      if (potential_link_id and potential_link_id != page_id)
        execute_sometime "update pages set direct_link_id = #{potential_link_id} where id = #{page_id}"
        return
      end
    end
    execute_sometime "update pages set direct_link_id = null where id = #{page_id}"
    return
  end

  def sql_fake_escape(string)
    string.gsub(/'/, "''") #Not yet unit tested
  end

  def analysis_output(res = "")
    all_link_chains_output(res) if @configuration.include_output?(:all_link_chains)
    most_common_chain_endings_output(res) if @configuration.include_output?(:most_common_chain_endings)
    most_backlinks_output(res) if @configuration.include_output?(:most_backlinks)
    most_total_backlinks_output(res) if @configuration.include_output?(:most_total_backlinks)
    most_backlinks_merged_output(res) if @configuration.include_output?(:most_backlinks_merged)
    longest_chains_output(res) if @configuration.include_output?(:longest_chains)
    page_count_output(res) if @configuration.include_output?(:page_count)
    res
  end

  def all_link_chains_output(res = "")
    minimum_threshold = nil #Doesn't make sense for string outputs
    do_reporting(:title_string, minimum_threshold, :link_chain_string, res)
  end

  def most_common_chain_endings_output(res = "")
    chain_ends = {}
    pages.each do |page|
      chain_end = page.link_chain_end
      unless chain_ends[chain_end]
        chain_ends[chain_end] = 0
      end
      chain_ends[chain_end] += 1
    end
    raise "You've loaded me from active record, haven't you??" if @configuration.nil?
    minimum_threshold = @configuration.most_common_chain_endings_minimum_threshold
    chain_ends.reject!{|page, value| value < minimum_threshold} unless minimum_threshold.nil?
    chain_ends_a = chain_ends.sort_by {|page, value| [value, page.title_string]}
    res << "Most common chain ending:\n"
    chain_ends_a.each do |page, frequency|
      res << "#{page.title_string}\t#{frequency}\n"
    end
    res
  end

  def self.new_with_configuration(options)
    configuration = RepositoryConfiguration.new(options)
    result = self.new(configuration)
    result.save!
    result
  end

  def initialize(configuration)
    super({})
    @configuration = configuration
  end

  def each_page
    offset = 0
    limit = 100
    while true
      pages_chunk = pages.find(:all, :order => "id", :limit => limit, :offset => offset)
      break if pages_chunk.empty?
      pages_chunk.each {|page| yield page}
      offset += limit
    end
  end

  def build_total_backlink_counts
    raise "You've already run this" if pages.any? {|page| page.total_backlink_count}
    each_page {|page| page.link_chain}
    each_page {|page| execute_sometime("update pages set total_backlink_count = 0")}
    #each_page {|page| page.reload}
    each_page do |page|
      linked_to_pages = page.link_chain_without_loop[1..-1] #Don't count the original page
      linked_to_pages.each do |linked_to_page|
        execute_sometime("update pages set total_backlink_count = total_backlink_count + 1 where id = #{linked_to_page.id}")
      end
    end
    #pages(true)
  end

  def page_count
    pages.size
  end

  def page_count_output(res = "")
    res << "#{page_count} pages total."
  end

  def most_backlinks_output(res = "")
    do_reporting(:direct_backlink_count, @configuration.most_backlinks_minimum_threshold, :backlinks_string, res)
  end

  def most_total_backlinks_output(res = "")
    do_reporting(:total_backlink_count, @configuration.most_total_backlinks_minimum_threshold, :total_backlink_count_string, res)
  end

  def most_backlinks_merged_output(res = "")
    do_reporting(:backlink_merge_count, @configuration.most_backlinks_merged_minimum_threshold, :backlink_merge_count_string, res)
  end

  def longest_chains_output(res = "")
    do_reporting(:chain_without_loop_length, @configuration.longest_chains_minimum_threshold, :chain_without_loop_length_string, res)
  end

  #To do: add the option of a maximum number of results
  def do_reporting(sorting_method, minimum_threshold, string_method, result)
    local_pages = pages
    local_pages = pages.reject {|page| page.send(sorting_method) < minimum_threshold} unless minimum_threshold.nil?
    local_pages = local_pages.sort_by {|page| page.send(sorting_method)}
    local_pages.each do |page|
      addition = page.send(string_method)
      result << addition << "\n" unless addition.empty?
    end
    result
  end

end

class RepositoryConfiguration
  def initialize(options)
    defaults = {:outputs => [:all_link_chains, :most_common_chain_endings, :most_backlinks, :most_total_backlinks, :most_backlinks_merged, :page_count]}
    @options = defaults.merge(options)
  end

  def include_output?(output)
    return @options[:outputs].include?(output)
  end

  def most_common_chain_endings_minimum_threshold
    return nil if @options[:most_common_chain_endings_output].nil?
    @options[:most_common_chain_endings_output][:minimum_threshold]
  end

  def most_backlinks_minimum_threshold
    return nil if @options[:most_backlinks_output].nil?
    @options[:most_backlinks_output][:minimum_threshold]
  end

  def most_total_backlinks_minimum_threshold
    return nil if @options[:most_total_backlinks_output].nil?
    @options[:most_total_backlinks_output][:minimum_threshold]
  end

  def most_backlinks_merged_minimum_threshold
    return nil if @options[:most_backlinks_merged_output].nil?
    @options[:most_backlinks_merged_output][:minimum_threshold]
  end

  def longest_chains_minimum_threshold
    return nil if @options[:longest_chains_output].nil?
    @options[:longest_chains_output][:minimum_threshold]
  end
end


class TitleNilError < RuntimeError
end

class TitleNotFoundError < RuntimeError
end

