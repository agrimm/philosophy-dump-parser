$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "test")

require "test/unit"

class TestRepository < Test::Unit::TestCase

  def setup
  end

  def test_all_page_link_chains_sorted_alphabetically
    test_helper_page_creation_object = TestHelperPageCreation.new
    pages = Array.new(10).map {test_helper_page_creation_object.create_page}
    pages.reverse
    pages[2], pages[7] = pages[7], pages[2]
    Page.build_links(pages)
    assert_page_link_chains_sorted_alphabetically(pages)
  end

  def test_most_common_chain_endings_sorted_by_value
    test_helper_page_creation_object = TestHelperPageCreation.new
    popular_page = test_helper_page_creation_object.create_page
    pages = Array.new(10).map {test_helper_page_creation_object.create_page_linking_to_pages([popular_page.title])}
    pages << popular_page
    pages.reverse
    pages[2], pages[7] = pages[7], pages[2]
    Page.build_links(pages)
    assert_most_common_chain_endings_sorted_by_value(pages)
  end

  def test_most_common_chain_endings_also_sorted_alphabetically
    test_helper_page_creation_object = TestHelperPageCreation.new
    popular_page = test_helper_page_creation_object.create_page
    pages = Array.new(10).map {test_helper_page_creation_object.create_page_linking_to_pages([popular_page.title])}
    pages << popular_page
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
    target_page = test_helper_page_creation_object.create_page
    linking_page = test_helper_page_creation_object.create_page_linking_to_pages([target_page.title])
    pages = [target_page, linking_page]
    Page.build_links(pages)
    repository = Repository.new(pages)
    expected_string = "1 pages link to #{target_page.title_string}\n"
    assert_equal expected_string, repository.most_backlinks_string
  end

  def test_backlink_counts
    test_helper_page_creation_object = TestHelperPageCreation.new
    philosophy_page, looping_page = test_helper_page_creation_object.create_network([["Philosophy page", ["Looping page"]], ["Looping page", ["Philosophy page"]] ])
    general_pages = test_helper_page_creation_object.create_network([[nil, ["Philosophy page"]]] * 10)
    pages = general_pages + [philosophy_page, looping_page]
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
    network = [["Philosophy page", ["Looping page"]], ["Looping page", ["Philosophy page"]], [nil, ["Philosophy page"]] ]
    philosophy_page, looping_page, popular_page = test_helper_page_creation_object.create_network(network)
    general_pages = test_helper_page_creation_object.create_network([[nil, [popular_page.title]]] * 10)
    pages = general_pages + [philosophy_page, looping_page, popular_page]
    Page.build_links(pages)
    expected_popular_page_string = "#{popular_page.title}, which links to Philosophy page, has 10 backlinks"
    actual_popular_page_string = popular_page.total_backlink_count_string
    assert_equal expected_popular_page_string, actual_popular_page_string
  end

  def assert_page_link_chains_sorted_alphabetically(pages)
    repository = Repository.new(pages)
    res = repository.analysis_output_string
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
    res = repository.most_common_chain_endings_string
    previous_value = nil
    res.split("\n")[1..-1].each do |line|
      current_value = Integer(line.split.last)
      assert (previous_value.nil? or previous_value <= current_value)
    end
  end

  def assert_most_common_chain_endings_also_sorted_alphabetically(pages)
    repository = Repository.new(pages)
    res = repository.most_common_chain_endings_string
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

