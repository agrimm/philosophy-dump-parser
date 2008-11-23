#Wikipedia text document
class WikiText

  def initialize(document_text)
    @document_text = document_text
  end

  #Remove from MediaWiki text anything that is surrounded by <nowiki>
  def parse_nowiki(wiki_text)
    loop do
      #Delete anything paired by nowiki, non-greedily
      #Assumes that there aren't nested nowikis
      substitution_made = wiki_text.gsub!(%r{<nowiki>(.*?)</nowiki>}im,"")
      break unless substitution_made
    end
    wiki_text
  end

  #Remove from MediaWiki text anything within a template
  def parse_templates(wiki_text)
    loop do
      #Delete anything with paired {{ and }}, so long as no opening braces are inside
      #Should closing braces inside be forbidden as well?
      substitution_made = wiki_text.gsub!(%r{\{\{([^\{]*?)\}\}}im,"")
      break unless substitution_made
    end
    wiki_text
  end

  #Remove from MediaWiki text anything in an external link
  #This will remove the description of the link as well - for now
  def parse_external_links(wiki_text)
    #Delete everything starting with an opening square bracket, continuing with non-bracket characters until a colon, then any characters until it reaches a closing square bracket
    wiki_text.gsub!(%r{\[[^\[]+?:[^\[]*?\]}im, "")
    wiki_text
  end

  #Remove paired XHTML-style syntax 
  def parse_paired_tags(wiki_text)
    #Remove paired tags
    wiki_text.gsub!(%r{<([a-zA-Z]*)>(.*?)</\1>}im, '\2')
    wiki_text
  end

  #Remove non-paired XHTML-style syntax
  def parse_unpaired_tags(wiki_text)
    wiki_text.gsub!(%r{<[a-zA-Z]*/>}im, "")
    wiki_text
  end

  #Remove links to other namespaces (eg [[Wikipedia:Manual of Style]]) , to media (eg [[Image:Wiki.png]]) and to other wikis (eg [[es:Plancton]])
  def parse_non_direct_links(wiki_text)
    wiki_text.gsub!(%r{\[\[[^\[\]]*?:([^\[]|\[\[[^\[]*\]\])*?\]\]}im, "")
    wiki_text
  end

  #Remove from wiki_text anything that could confuse the program
  def parse_wiki_text(wiki_text)
    wiki_text = parse_nowiki(wiki_text)
    wiki_text = parse_templates(wiki_text)
    wiki_text = parse_paired_tags(wiki_text)
    wiki_text = parse_unpaired_tags(wiki_text)
    wiki_text = parse_non_direct_links(wiki_text)
    wiki_text = parse_external_links(wiki_text) #Has to come after parse_non_direct_links for now
    wiki_text
  end

  #Look for wikilinks in a piece of text
  def linked_articles()
    parsed_wiki_text = parse_wiki_text(String(@document_text))
    unparsed_match_arrays = parsed_wiki_text.scan(%r{\[\[([^\]\#\|]*)([^\]]*?)\]\]}im)
    parsed_wiki_article_titles = []
    unparsed_match_arrays.each do |unparsed_match_array|
      unparsed_title = unparsed_match_array.first
      parsed_title = unparsed_title.gsub(/_+/, " ")
      parsed_wiki_article_titles << parsed_title
    end
    parsed_wiki_article_titles.uniq
  end

end

