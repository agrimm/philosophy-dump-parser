$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "test")

require "test/unit"
require "helper_xml_creation"
require "repository"

class TestRepository < Test::Unit::TestCase

  def setup
  end

  def test_all_page_link_chains_sorted_alphabetically
    test_helper_page_creation_object = TestHelperPageCreation.new
    pages = Array.new(10).map {test_helper_page_creation_object.create_page({:article_list=>{}})}
    pages.reverse
    pages[2], pages[7] = pages[7], pages[2]
    Page.build_links(pages)
    assert_page_link_chains_sorted_alphabetically(pages)
  end

  def test_most_common_chain_endings_sorted_by_value
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [["Popular page", []]]
    network += [[nil, ["Popular page"]]] * 10
    pages = test_helper_page_creation_object.create_network(network)
    popular_page = pages[0]
    pages.reverse
    pages[2], pages[7] = pages[7], pages[2]
    Page.build_links(pages)
    assert_most_common_chain_endings_sorted_by_value(pages)
  end

  def test_most_common_chain_endings_also_sorted_alphabetically
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [["Popular page", []]]
    network += [[nil, ["Popular page"]]] * 10
    pages = test_helper_page_creation_object.create_network(network)
    popular_page = pages[0]
    pages.reverse
    pages[2], pages[7] = pages[7], pages[2]
    Page.build_links(pages)
    assert_most_common_chain_endings_also_sorted_alphabetically(pages)
  end

  def test_can_count_pages
    pages = Array.new(10).map {TestHelperPageCreation.new}
    repository = Repository.new(pages)
    assert_equal 10, repository.page_count
  end

  def test_can_list_most_linked_to_pages
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [["Target page", []], [nil, ["Target page"]]]
    pages = test_helper_page_creation_object.create_network(network)
    target_page = pages[0]
    Page.build_links(pages)
    repository = Repository.new(pages)
    expected_string = "1 pages link to #{target_page.title_string}\n"
    assert_equal expected_string, repository.most_backlinks_output
  end

  def test_backlink_counts
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [["Philosophy page", ["Looping page"]], ["Looping page", ["Philosophy page"]] ]
    network += [[nil, ["Philosophy page"]]] * 10
    pages = test_helper_page_creation_object.create_network(network)
    philosophy_page, looping_page, *general_pages = pages
    Page.build_links(pages)
    philosophy_expected_backlink_count = pages.size - 2 #Looping page doesn't contribute to the count. This is probably bad.
    looping_page_expected_backlink_count = 0 #Neither from philosophy or from looping page
    general_pages_expected_backlink_count = 0
    assert_equal philosophy_expected_backlink_count, philosophy_page.total_backlink_count
    assert_equal looping_page_expected_backlink_count, looping_page.total_backlink_count
    general_pages.each {|page| assert_equal general_pages_expected_backlink_count, page.total_backlink_count}
  end

  def test_backlink_count_reporting
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [["Philosophy page", ["Looping page"]], ["Looping page", ["Philosophy page"]], ["Popular page", ["Philosophy page"]] ]
    network += [[nil, ["Popular page"]]] * 10
    pages = test_helper_page_creation_object.create_network(network)
    philosophy_page, looping_page, popular_page, *general_pages = pages
    Page.build_links(pages)
    expected_popular_page_string = "#{popular_page.title}, which links to Philosophy page, has 10 backlinks"
    actual_popular_page_string = popular_page.total_backlink_count_string
    assert_equal expected_popular_page_string, actual_popular_page_string
  end

  def test_merge_count_reporting
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Philosophy page", []], ["Popular page 1", ["philosophy page"]], ["Popular page 2", ["philosophy page"]] ]
    network += [[nil, ["popular page 1"]]] * 5
    network += [[nil, ["popular page 2"]]] * 10
    pages = test_helper_page_creation_object.create_network(network)
    Page.build_links(pages)
    philosophy_page = pages.first
    popular_page_1 = pages[1]
    popular_page_2 = pages[2]
    repository = Repository.new(pages)

    expected_report = ""
    expected_report << popular_page_1.backlink_merge_count_string << "\n"
    expected_report << philosophy_page.backlink_merge_count_string << "\n"
    expected_report << popular_page_2.backlink_merge_count_string << "\n"
    actual_report = repository.most_backlinks_merged_output
    assert_equal expected_report, actual_report
  end

  def assert_page_link_chains_sorted_alphabetically(pages)
    repository = Repository.new(pages)
    res = repository.analysis_output
    previous_title = nil
    line_count = 0
    res.each_line do |line|
      break if line =~ /Most common chain ending:/
      line_count += 1
      current_title = line.split("links to").first
      assert (previous_title.nil? or (previous_title < current_title)), "#{previous_title} was listed before #{current_title}"
      previous_title = current_title
    end
    assert_equal pages.size, line_count
  end

  def assert_most_common_chain_endings_sorted_by_value(pages)
    repository = Repository.new(pages)
    res = repository.most_common_chain_endings_output
    previous_value = nil
    res.split("\n")[1..-1].each do |line|
      current_value = Integer(line.split.last)
      assert (previous_value.nil? or previous_value <= current_value)
    end
  end

  def assert_most_common_chain_endings_also_sorted_alphabetically(pages)
    repository = Repository.new(pages)
    res = repository.most_common_chain_endings_output
    previous_value = nil
    previous_title = nil
    assert res.split("\n")[0] == "Most common chain ending:"
    res.split("\n")[1..-1].each do |line|
      current_value = Integer(line.split.last)
      current_title = line.split("\t").first
      assert (previous_title.nil? or previous_title < current_title or (previous_value < current_value))
      previous_value = current_value
      previous_title = current_title
    end
  end

end

