class Repository < ActiveRecord::Base

  has_many :pages

  def new_page_if_valid(title, page_id)
    if page_parameters_valid?(title)
      title = nil if @nil_titles
      page = Page.new(title, page_id, self)
      page.save
      pages << page
      return page
    else
      return nil
    end
  end

  def page_parameters_valid?(title)
    return false unless page_title_valid?(title) #Not heckle proof?
    return true
  end

  def page_title_valid?(title)
    return true if title.nil? #Allow nil titles
    return false if title =~ /:/
    raise "Invalid title #{title}" if title != Page.upcase_first_letter(title)
    return true
  end

  def analysis_output(res = "")
    all_link_chains_output(res) if @configuration.include_output?(:all_link_chains)
    most_common_chain_endings_output(res) if @configuration.include_output?(:most_common_chain_endings)
    most_backlinks_output(res) if @configuration.include_output?(:most_backlinks)
    most_total_backlinks_output(res) if @configuration.include_output?(:most_total_backlinks)
    most_backlinks_merged_output(res) if @configuration.include_output?(:most_backlinks_merged)
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
      page.clear_link_chain_cache
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
    self.new(configuration)
  end

  def initialize(configuration)
    super({})
    @configuration = configuration
  end

  def build_total_backlink_counts
    raise "You've already run this" if pages.any? {|page| page.total_backlink_count}
    pages.each {|page| page.total_backlink_count = 0; page.save!}
    pages.each {|page| page.reload}
    pages.each do |page|
      linked_to_pages = page.link_chain_without_loop[1..-1] #Don't count the original page
      linked_to_pages.each do |linked_to_page|
        linked_to_page.increment_total_backlink_count
        linked_to_page.save!
      end
      page.clear_link_chain_cache
    end
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

  def do_reporting(sorting_method, minimum_threshold, string_method, result)
    local_pages = pages
    local_pages = pages.reject {|page| page.send(sorting_method) < minimum_threshold} unless minimum_threshold.nil?
    local_pages = local_pages.sort_by {|page| page.send(sorting_method)}
    local_pages.each do |page|
      addition = page.send(string_method)
      result << addition << "\n" unless addition.empty?
      page.clear_link_chain_cache #Clean up for memory purposes - may not be applicable for all string_methods though
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
end
