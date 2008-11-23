require "wiki_text"

class Page
  attr_accessor :text, :title, :direct_link

  def initialize(title, text)
    raise unless self.class.valid?(title, text)
    @title, @text = title, text
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

  def self.build_links(pages)
    pages.each do |page|
      page.build_links(pages)
    end
  end

  def build_links(pages)
    wiki_text = WikiText.new(String(@text))
    linked_articles = wiki_text.linked_articles
    linked_articles.any? do |linked_article|
      @direct_link = pages.find do |page|
        (page.title == linked_article and page.title != self.title) # 
      end
    end
  end

  def immediate_link_string(current_link_chain)
    if current_link_chain.include?(@direct_link)
      "links to previously encountered #{@direct_link.title}"
    elsif @direct_link
      "links to #{@direct_link.title}"
    else
      "links to nothing"
    end
  end

  def link_chain_string
    link_chain = [self]
    while (link_chain.last.direct_link and not (link_chain.include?(link_chain.last.direct_link)) )
       link_chain << link_chain.last.direct_link
    end
    string = link_chain.first.title + " "
    link_chain.each_with_index do |chain_item, index|
      string << ", which " unless index == 0
      string << chain_item.immediate_link_string(link_chain[0..index])
    end
    string << "."
  end

end

