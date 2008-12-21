class Repository

  def analysis_output_string
    res = all_link_chain_strings
    res += most_common_chain_endings_string
    res += page_count_string
  end

  def all_link_chain_strings
    pages = @pages.sort_by{|page| page.title_string}
    res = ""
    pages.each do |page|
      res << page.link_chain_string << "\n"
    end
    res
  end

  def most_common_chain_endings_string
    res = ""
    chain_ends = {}
    @pages.each do |page|
      chain_end = page.link_chain_end
      unless chain_ends[chain_end]
        chain_ends[chain_end] = 0
      end
      chain_ends[chain_end] += 1
    end
    chain_ends_a = chain_ends.sort_by {|page, value| [value, page.title_string]}
    res << "Most common chain ending:\n"
    chain_ends_a.each do |page, frequency|
      res << "#{page.title_string}\t#{frequency}\n"
    end
    res
  end

  def initialize(pages)
    @pages = pages
  end

  def page_count
    @pages.size
  end

  def page_count_string
    res = "#{page_count} pages total."
  end

end
