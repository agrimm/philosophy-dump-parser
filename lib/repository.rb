class Repository

  def new_page_if_valid(title, page_id, text, article_hash)
    if page_parameters_valid?(title)
      return Page.new(title, page_id, text, article_hash)
    else
      return nil
    end
  end

  def page_parameters_valid?(title)
    return false unless page_title_valid?(title)
    return true
  end

  def page_title_valid?(title)
    return true if title.nil? #Allow nil titles
    return false if title =~ /:/
    raise "Invalid title #{title}" if title != Page.upcase_first_letter(title)
    return true
  end

  def self.do_dump(object, filename)
    debug_mode = false
    return unless debug_mode
    STDERR.puts "Item dumped to #{filename} at #{Time.now.to_s}"
    File.open(filename, "w") do |f|
      Marshal.dump(object, f)
    end
  end

  def analysis_output(res = "")
    self.class.do_dump(@pages, "analysis_output1.bin")
    all_link_chains_output(res)
    self.class.do_dump(@pages, "analysis_output2.bin")
    most_common_chain_endings_output(res)
    self.class.do_dump(@pages, "analysis_output3.bin")
    most_backlinks_output(res)
    self.class.do_dump(@pages, "analysis_output4.bin")
    most_total_backlinks_output(res)
    self.class.do_dump(@pages, "analysis_output5.bin")
    most_backlinks_merged_output(res)
    self.class.do_dump(@pages, "analysis_output6.bin")
    page_count_output(res)
    self.class.do_dump(@pages, "analysis_output7.bin")
    res
  end

  def all_link_chains_output(res = "")
    do_reporting(:title_string, :link_chain_string, res)
  end

  def most_common_chain_endings_output(res = "")
    chain_ends = {}
    @pages.each do |page|
      chain_end = page.link_chain_end
      unless chain_ends[chain_end]
        chain_ends[chain_end] = 0
      end
      chain_ends[chain_end] += 1
      page.clear_link_chain_cache
    end
    chain_ends_a = chain_ends.sort_by {|page, value| [value, page.title_string]}
    res << "Most common chain ending:\n"
    chain_ends_a.each do |page, frequency|
      res << "#{page.title_string}\t#{frequency}\n"
    end
    res
  end

  def initialize(pages = [])
    @pages = pages
  end

  def page_count
    @pages.size
  end

  def page_count_output(res = "")
    res << "#{page_count} pages total."
  end

  def most_backlinks_output(res = "")
    do_reporting(:direct_backlink_count, :backlinks_string, res)
  end

  def most_total_backlinks_output(res = "")
    do_reporting(:total_backlink_count, :total_backlink_count_string, res)
  end

  def most_backlinks_merged_output(res = "")
    do_reporting(:backlink_merge_count, :backlink_merge_count_string, res)
  end

  def do_reporting(sorting_method, string_method, result = "")
    pages = @pages.sort_by {|page| page.send(sorting_method)}
    pages.each do |page|
      addition = page.send(string_method)
      result << addition << "\n" unless addition.empty?
      page.clear_link_chain_cache #Clean up for memory purposes - may not be applicable for all string_methods though
    end
    result
  end

end
