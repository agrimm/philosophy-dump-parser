class Repository

  def analysis_output_string
    res = all_link_chain_strings
    res += most_common_chain_endings_string
    res += most_backlinks_string
    res += most_total_backlinks_string
    res += most_backlinks_merged_string
    res += page_count_string
  end

  def all_link_chain_strings
    res = do_reporting(:title_string, :link_chain_string)
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

  def most_backlinks_string
    res = do_reporting(:direct_backlink_count, :backlinks_string)
  end

  def most_total_backlinks_string
    do_reporting(:total_backlink_count, :total_backlink_count_string)
  end

  def most_backlinks_merged_string
    do_reporting(:backlink_merge_count, :backlink_merge_count_string)
  end

  def do_reporting(sorting_method, string_method)
    pages = @pages.sort_by {|page| page.send(sorting_method)}
    res_strings = []
    pages.each do |page|
      addition = page.send(string_method)
      res_strings << addition << "\n" unless addition.empty?
    end
    res_strings.join
  end

end
