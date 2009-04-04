require "wiki_text"
require "database_connection"

class Page < ActiveRecord::Base

  belongs_to :repository
  belongs_to :direct_link, :class_name => "Page", :foreign_key => "direct_link_id"
  has_many :backlinks, :class_name => "Page", :foreign_key => "direct_link_id"

  def page_id
    local_id
  end

  #Add text to set a direct link
  def add_text(text)
    wiki_text = WikiText.new(text)
    self.direct_link = nil
    wiki_text.linked_articles.each do |potential_title|
      page = repository.pages.find_by_title(self.class.upcase_first_letter(potential_title))
      if (page and page != self)
        self.direct_link = page
        break
      end
    end
    self.save! #This and other saves are a temporary measure only
  end

  def self.upcase_first_letter(string)
    return string if string == ""
    return string[0..0].upcase + string[1..-1]
  end

  #Title string - this is for display purposes, not for searching
  def title_string
    self.title
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

  def increment_total_backlink_count
    self.total_backlink_count += 1
  end

  def total_backlink_count_string
    raise if total_backlink_count.nil?
    return "" if self.total_backlink_count == 0 #Currently not heckle-proof
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
