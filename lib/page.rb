require "wiki_text"

class Page
  attr_accessor :text, :title, :direct_link, :backlinks

  def initialize(title, text)
    raise unless self.class.valid?(title, text)
    @title, @text = title, text
    @backlinks = []
  end

  def self.new_if_valid(title, text)
    if valid?(title, text)
      return new(title, text)
    else
      return nil
    end
  end

  def self.valid?(title, text)
    return false if title =~ /:/
    return false if text.empty?
    return true
  end

  def self.build_links(page_array)
    pages = {}
    page_array.each {|page| pages[page.title] = page}
    #raise unless page_array.size == pages.size #No two pages should have the same title, but the test example methods need to be cleaned up first

    pages.each_value do |page|
      page.build_links(pages)
    end
  end

  #Title string - this is for display purposes, not for searching
  def title_string
    @title
  end

  #Does the page match the supplied title?
  #(Handles the scenario of a lower case wikilink matching an article)
  def title_matches?(title)
    return (title.capitalize == @title or title == @title) #Internationalization issues
  end

  def build_links(pages)
    wiki_text = WikiText.new(String(@text))
    linked_articles = wiki_text.linked_articles
    linked_articles.any? do |linked_article|
      @direct_link = (pages[linked_article] or pages[linked_article.capitalize])
      @direct_link = nil if @direct_link == self
      @direct_link
    end
    @direct_link.add_backlink(self) unless @direct_link.nil?
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
    string = link_chain.first.title_string + " "
    link_chain.each_with_index do |chain_item, index|
      string << ", which " unless index == 0
      string << chain_item.immediate_link_string(link_chain[0..index])
    end
    string << "."
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
    @link_chain_without_loop ||= build_link_chain_without_loop
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

  def backlinks_string
    if @backlinks.empty?
      return ""
    else
      return "#{@backlinks.size} pages link to #{title_string}"
    end
  end

end

