$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "test")


require "test/unit"

require "helper_xml_creation"
require "page_xml_parser"
require "repository"

class TestPage < Test::Unit::TestCase
  def setup
  end

  def test_links_work_with_lower_case
    lowercase_title = "finnska"
    uppercase_title = "Finnska"
    test_helper_xml_creation_object = TestHelperXmlCreation.new

    linked_to_page_title = uppercase_title
    linked_to_page_text = test_helper_xml_creation_object.expected_mainspace_page_revision_text_text
    linked_to_page = Page.new(linked_to_page_title, linked_to_page_text)

    original_page_title = test_helper_xml_creation_object.generate_random_title_text
    original_page_text = test_helper_xml_creation_object.mainspace_page_revision_text_text_with_one_specified_link(lowercase_title)
    original_page = Page.new(original_page_title, original_page_text)

    Page.build_links([original_page, linked_to_page])
    assert_direct_link_to original_page, linked_to_page
  end

  def test_ignore_hatnotes
    test_helper_page_creation_object = TestHelperPageCreation.new
    non_target_page = test_helper_page_creation_object.create_page
    target_page = test_helper_page_creation_object.create_page
    original_page = test_helper_page_creation_object.create_page({:text => ":For the pokemon character, see [[#{non_target_page.title}]]\n\n[[#{target_page.title}]]"})
    Page.build_links([original_page, non_target_page, target_page])
    assert_direct_link_to original_page, target_page
  end

  def test_all_page_link_chains_sorted_alphabetically
    test_helper_page_creation_object = TestHelperPageCreation.new
    pages = Array.new(10).map {test_helper_page_creation_object.create_page}
    pages.reverse
    pages[2], pages[7] = pages[7], pages[2]
    assert_page_link_chains_sorted_alphabetically(pages)
  end

  def test_most_common_chain_endings_sorted_by_value
    test_helper_page_creation_object = TestHelperPageCreation.new
    popular_page = test_helper_page_creation_object.create_page
    pages = Array.new(10).map {test_helper_page_creation_object.create_page_linking_to_pages([popular_page.title])}
    pages << popular_page
    pages.reverse
    pages[2], pages[7] = pages[7], pages[2]
    assert_most_common_chain_endings_sorted_by_value(pages)
  end

  def test_most_common_chain_endings_also_sorted_alphabetically
    test_helper_page_creation_object = TestHelperPageCreation.new
    popular_page = test_helper_page_creation_object.create_page
    pages = Array.new(10).map {test_helper_page_creation_object.create_page_linking_to_pages([popular_page.title])}
    pages << popular_page
    pages.reverse
    pages[2], pages[7] = pages[7], pages[2]
    assert_most_common_chain_endings_also_sorted_alphabetically(pages)
  end

  def assert_direct_link_to(originating_page, expected_target_page)
    actual_target_page = originating_page.direct_link
    assert_equal expected_target_page, actual_target_page
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
