require "wiki_text"

class Page
  attr_reader :title, :backlinks, :total_backlink_count

  def initialize(title, text, article_hash = nil)
    raise unless self.class.valid?(title, text)
    @title = title
    @backlinks = []
    @total_backlink_count = 0
    wiki_text = WikiText.new(String(text))
    @articles_linked_somewhere_in_the_text = wiki_text.linked_articles
    @link_ought_to_exist = determine_if_link_ought_to_exist(@articles_linked_somewhere_in_the_text, article_hash)
    shortern_link_list_if_possible(@articles_linked_somewhere_in_the_text, article_hash)
  end

  def self.new_if_valid(title, text, article_hash)
    if valid?(title, text)
      return new(title, text, article_hash)
    else
      return nil
    end
  end

  def self.valid?(title, text)
    return false unless title_valid?(title)
    #return false if text.empty?
    return true
  end

  def self.title_valid?(title)
    return false if title =~ /:/
    raise "Invalid title #{title}" if title != upcase_first_letter(title)
    return true
  end

  def determine_if_link_ought_to_exist(articles_linked_somewhere_in_the_text, article_hash)
    return false if article_hash.nil? #It may be possible a direct link ought to be found, but we won't know until we do it
    articles_linked_somewhere_in_the_text.any? do |potential_link|
      is_valid_link_for_hash?(potential_link, article_hash)
    end
  end

  def shortern_link_list_if_possible(articles_linked_somewhere_in_the_text, article_hash)
    return if article_hash.nil?
    first_match_index = nil
    articles_linked_somewhere_in_the_text.each_with_index do |link, i|
      if is_valid_link_for_hash?(link, article_hash)
        first_match_index = i
        articles_linked_somewhere_in_the_text.slice!((first_match_index+1)..-1)
        articles_linked_somewhere_in_the_text.slice!(0...first_match_index)
        return
      end
    end
    articles_linked_somewhere_in_the_text.slice!(0..-1)
  end

  #Next iteration: change this string manipulation to something correct
  def is_valid_link_for_hash?(link_string, hash)
    return (hash.has_key?(self.class.upcase_first_letter(link_string)) and self.class.upcase_first_letter(link_string) != self.title)
  end

  def self.upcase_first_letter(string)
    return string if string == ""
    return string[0..0].upcase + string[1..-1]
  end

  def self.build_links(page_array)
    self.do_dump(page_array, "before_build_links.bin")
    self.build_direct_links(page_array)
    self.do_dump(page_array, "after_direct_links.bin")
    self.build_total_backlink_counts(page_array)
    self.do_dump(page_array, "after_total_backlinks.bin")
  end

  def self.do_dump(object, filename)
    debug_mode = false
    return unless debug_mode
    STDERR.puts "Item dumped to #{filename} at #{Time.now.to_s}"
    dump = Marshal.dump(object)
    File.open(filename, "w") do |f|
      f.write(dump)
    end
  end

  def self.build_direct_links(page_array)
    pages = {}
    page_array.each {|page| pages[page.title] = page}
    raise unless page_array.size == pages.size

    pages.each_value do |page|
      page.build_links(pages)
    end
    GC.start if pages.size > 20
  end

  def self.build_total_backlink_counts(page_array)
    page_array.each do |page|
      linked_to_pages = page.link_chain_without_loop[1..-1] #Don't count the original page
      linked_to_pages.each do |linked_to_page|
        linked_to_page.increment_total_backlink_count
      end
    end
  end

  #Title string - this is for display purposes, not for searching
  def title_string
    @title
  end

  def direct_link
    raise unless (@direct_link or defined?(@direct_link))
    @direct_link
  end

  def build_links(pages)
    @direct_link = nil #Just to handle a scenario of @articles_linked_somewhere_in_the_text being empty
    @articles_linked_somewhere_in_the_text.any? do |linked_article|
      @direct_link = pages[self.class.upcase_first_letter(linked_article)]
      @direct_link = nil if @direct_link == self
      @direct_link
    end
    @direct_link.add_backlink(self) unless @direct_link.nil?
    raise "Problem with #{self.title}, which links to (at least) #{@articles_linked_somewhere_in_the_text.inspect}, doesn't link to anything but ought to do so." if @direct_link.nil? and @link_ought_to_exist
    @articles_linked_somewhere_in_the_text = nil
  end

  def immediate_link_string(current_link_chain)
    if current_link_chain.include?(@direct_link)
      "links to previously encountered #{@direct_link.title_string}"
    elsif @direct_link
      "links to #{@direct_link.title_string}"
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
    #string_aggregator = link_chain.first.title_string << " " #Side effects!
    #string_aggregator = link_chain.first.title_string + " "

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
    @backlinks << page
  end

  def direct_backlink_count
    @backlinks.size
  end

  def backlinks_string
    if @backlinks.empty?
      return ""
    else
      return "#{@backlinks.size} pages link to #{title_string}"
    end
  end

  def increment_total_backlink_count
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
    counts_in_backlinks = @backlinks.map {|page| page.total_backlink_count}
    indirect_backlink_total = counts_in_backlinks.inject(0) {|total, value| total + value}
    largest_count_in_backlinks = (counts_in_backlinks.max or 0)
    indirect_backlink_merging = indirect_backlink_total - largest_count_in_backlinks
    direct_backlink_merging = [@backlinks.size - 1, 0].max
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
