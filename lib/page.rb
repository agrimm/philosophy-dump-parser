require "wiki_text"
require "database_connection"

class Page < ActiveRecord::Base

  belongs_to :repository

  def page_id
    local_id
  end

  def initialize(title, page_id, text, repository)
    super({:title=>title, :local_id => page_id})
    self.repository = repository
    raise if page_id < 1
    #@backlinks = [] #Initialize when first used
    #@total_backlink_count = 0 #Initialize when first used
    add_text(text)
  end

  #Add text to set a direct link
  def add_text(text)
    wiki_text = WikiText.new(text)
    @direct_link_page_id = nil
    wiki_text.linked_articles.each do |potential_title|
      page = repository.pages.find_by_title(self.class.upcase_first_letter(potential_title))
      if (page and page != self)
        @direct_link_page_id = page.local_id
        break
      end
    end
  end

  def self.upcase_first_letter(string)
    return string if string == ""
    return string[0..0].upcase + string[1..-1]
  end

  def self.build_links(page_array)
    self.build_direct_links(page_array)
    self.build_total_backlink_counts(page_array)
  end

  def self.build_direct_links(page_array)
    pages = self.build_page_id_hash(page_array)
    pages.each_value do |page|
      page.build_links(pages)
    end
  end

  def self.build_page_id_hash(page_array)
    pages = {}
    page_array.each {|page| pages[page.page_id] = page}
    raise unless page_array.size == pages.size
    pages
  end

  def self.build_total_backlink_counts(page_array)
    page_array.each do |page|
      linked_to_pages = page.link_chain_without_loop[1..-1] #Don't count the original page
      linked_to_pages.each do |linked_to_page|
        linked_to_page.increment_total_backlink_count
      end
      page.clear_link_chain_cache
    end
  end

  #Title string - this is for display purposes, not for searching
  def title_string
    self.title || "Page number #{page_id}"
  end

  def direct_link
    raise "Problem with #{self.inspect}" unless (@direct_link or defined?(@direct_link))
    @direct_link
  end

  def build_links(page_id_hash)
    raise if @direct_link_page_id == self.local_id
    if @direct_link_page_id.nil?
      @direct_link = nil
    else
      @direct_link = page_id_hash[@direct_link_page_id]
      raise if @direct_link.equal?(self)
      raise if @direct_link.nil?
      direct_link.add_backlink(self)
      @direct_link_page_id = nil
    end
  end

  def immediate_link_string(current_link_chain)
    if current_link_chain.include?(direct_link)
      "links to previously encountered #{direct_link.title_string}"
    elsif direct_link
      "links to #{direct_link.title_string}"
    else
      "links to nothing"
    end
  end

  def build_link_chain
    link_chain = [self]
    while (link_chain.last.direct_link and not (link_chain.include?(link_chain.last.direct_link)) )
       link_chain << link_chain.last.direct_link
    end
    link_chain
  end

  def link_chain_to_string(link_chain)
    string_aggregator = StringAggregator.new(link_chain.first.title_string) << " "
    link_chain.each_with_index do |chain_item, index|
      string_aggregator << ", which " unless index == 0
      string_aggregator << chain_item.immediate_link_string(link_chain[0..index])
    end
    string_aggregator << "."
    result = string_aggregator.to_s
    result
  end

  def build_link_chain_without_loop
    unless link_chain_enters_loop?
      return link_chain
    else
      link_chain_without_loop = []
      link_chain.each do |page|
        link_chain_without_loop << page
        if page == link_chain_end
          break
        end
      end
      return link_chain_without_loop
    end
  end

  def link_chain
    @link_chain ||= build_link_chain
  end

  def clear_link_chain_cache
    @link_chain = nil
  end

  def link_chain_without_loop
    #Currently called only once, so not caching it.
    build_link_chain_without_loop
  end

  def link_chain_string
    return link_chain_to_string(link_chain)
  end

  def link_chain_end
    link_chain.last.direct_link || link_chain.last
  end

  def link_chain_enters_loop?
    link_chain.last.direct_link
  end

  def add_backlink(page)
    @backlinks ||= []
    @backlinks << page
  end

  def backlinks
    @backlinks ||= []
  end

  def direct_backlink_count
    backlinks.size
  end

  def backlinks_string
    if backlinks.empty?
      return ""
    else
      return "#{backlinks.size} pages link to #{title_string}"
    end
  end

  #To do: replace with rails goodness
  def total_backlink_count
    @total_backlink_count || 0
  end

  def increment_total_backlink_count
    @total_backlink_count ||= 0
    @total_backlink_count += 1
  end

  def total_backlink_count_string
    return "" if self.total_backlink_count == 0
    string_aggregator = StringAggregator.new("#{title_string}")
    string_aggregator << ", which links to #{direct_link.title_string}," if direct_link
    string_aggregator << " has #{total_backlink_count} backlinks"
    res = string_aggregator.to_s
    return res
  end

  #The number of backlinks merged by this page
  def backlink_merge_count
    counts_in_backlinks = backlinks.map {|page| page.total_backlink_count}
    indirect_backlink_total = counts_in_backlinks.inject(0) {|total, value| total + value}
    largest_count_in_backlinks = (counts_in_backlinks.max or 0)
    indirect_backlink_merging = indirect_backlink_total - largest_count_in_backlinks
    direct_backlink_merging = [backlinks.size - 1, 0].max
    backlink_merge_count = indirect_backlink_merging + direct_backlink_merging
    backlink_merge_count
  end

  def backlink_merge_count_string
    return "" if (backlink_merge_count == 0)
    return "#{title_string} has merged #{backlink_merge_count} backlinks"
  end
end

class StringAggregator
  def initialize(first_string = nil)
    @array = []
    @array << first_string unless first_string.nil?
  end

  def <<(string)
    @array << string
    self
  end

  def to_s
    @array.join
  end
end
