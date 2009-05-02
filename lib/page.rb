require "wiki_text"
require "database_connection"

class Page < ActiveRecord::Base

  belongs_to :repository
  belongs_to :direct_link, :class_name => "Page", :foreign_key => "direct_link_id"
  has_many :backlinks, :class_name => "Page", :foreign_key => "direct_link_id"

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

  def self.find_pages_given_page_ids(page_ids)
    #Requires O(n) requests to the database
    #To do: See if http://stackoverflow.com/questions/801824 comes up with a better way
    result = page_ids.map{|p_id| find(p_id)}
    result
  end

  def link_chain
    page_ids = repository.calculate_link_chain_for_page_id(self.id)
    result = self.class.find_pages_given_page_ids(page_ids)
    result
  end

  def link_chain_without_loop
    page_ids = repository.calculate_link_chain_without_loop_for_page_id(self.id)
    result = self.class.find_pages_given_page_ids(page_ids)
    result
  end

  def link_chain_string
    return link_chain_to_string(link_chain)
  end

  def link_chain_end
    link_chain.last.direct_link || link_chain.last
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

  #insert method calculate_total_backlink_count here if appropriate

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

  #To do: change the string to emphasize that the chain has x links, not that it has
  #x pages in it
  def chain_without_loop_length_string
    return "" if (chain_without_loop_length.zero?)
    return "#{title_string} has a chain of length #{chain_without_loop_length}"
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

