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

#Some testing exists in tc_page_xml_parsing.rb

  def test_link_chain_without_loop
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Philosophy page", ["Looping page"]], ["Looping page", ["Philosophy page"]], [nil, ["Philosophy page"]] ]
    philosophy_page, looping_page, general_page = test_helper_page_creation_object.create_network(network)
    Page.build_links([philosophy_page, looping_page, general_page]) #Keep on forgetting this step!
    assert_link_chain_without_loop_matches general_page, [general_page, philosophy_page]
    assert_link_chain_without_loop_matches philosophy_page, [philosophy_page]
    assert_link_chain_without_loop_matches looping_page, [looping_page] #This feels wrong
  end

  def test_asking_for_link_chains_without_building_links_throws_exception
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Philosophy page", ["Looping page"]], ["Looping page", ["Philosophy page"]], [nil, ["Philosophy page"]] ]
    philosophy_page, looping_page, general_page = test_helper_page_creation_object.create_network(network)
    assert_raise(RuntimeError) {philosophy_page.link_chain}
  end

  def test_backlinks
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Target page", [] ], [nil, ["Target page"]] ]
    target_page, linking_page = test_helper_page_creation_object.create_network(network)
    Page.build_links([target_page, linking_page])
    expected_backlinks_for_target_page = [linking_page]
    expected_backlinks_for_linking_page = []
    assert_equal expected_backlinks_for_target_page, target_page.backlinks
    assert_equal expected_backlinks_for_linking_page, linking_page.backlinks
    assert_equal 1, target_page.direct_backlink_count
    assert_equal 0, linking_page.direct_backlink_count
  end

  def test_handle_non_linking_pages
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ [nil, [] ] ]
    page, = test_helper_page_creation_object.create_network(network)

    Page.build_links([page])
    assert_direct_link_to(page, nil)
    assert_link_chain_without_loop_matches(page, [page])
  end

  def test_backlink_merge_count_for_direct_backlinks
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["merging page", []], [nil, ["merging page"]], [nil, ["merging page"]] ]
    pages = test_helper_page_creation_object.create_network(network)
    Page.build_links(pages)
    merging_page = pages.first
    normal_page = pages[1]
    assert_equal 1, merging_page.backlink_merge_count, "Can't produce the right answer for a page merging direct backlinks"
    assert_equal 0, normal_page.backlink_merge_count, "Can't produce the right answer for a page with no backlinks"
  end

  def test_backlink_merge_count_for_indirect_backlinks
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["philosophy page", []], ["popular page 1", ["philosophy page"]], ["popular page 2", ["philosophy page"]] ]
    network += [[nil, ["popular page 1"]]] * 5
    network += [[nil, ["popular page 2"]]] * 10
    pages = test_helper_page_creation_object.create_network(network)
    Page.build_links(pages)
    philosophy_page = pages.first
    popular_page_1 = pages[1]
    popular_page_2 = pages[2]
    #The following is just checking my own arithmetic, rather than testing backlink_merge_count
    assert_equal 5, popular_page_1.total_backlink_count, "Calculation error by programmer"
    assert_equal 10, popular_page_2.total_backlink_count, "Calculation error by programmer"
    assert_equal 17, philosophy_page.total_backlink_count, "Calculation error by programmer"
    #Six has been contributed to the total backlink count by popular page 1, and eleven by popular page 2
    assert_equal 6, philosophy_page.backlink_merge_count, "Can't produce the right answer for a page merging indirect backlinks"
  end

  def test_backlink_merge_count_for_page_not_merging_anything
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["philosophy page", []], ["popular page 1", ["philosophy page"]] ]
    network += [[nil, ["popular page 1"]]] * 5
    pages = test_helper_page_creation_object.create_network(network)
    Page.build_links(pages)
    philosophy_page = pages.first
    assert_equal 0, philosophy_page.backlink_merge_count, "Can't produce the right answer for a page that merely continues a chain without merging anything"
  end

  def assert_direct_link_to(originating_page, expected_target_page)
    actual_target_page = originating_page.direct_link
    assert_equal expected_target_page, actual_target_page
  end

  def assert_link_chain_without_loop_matches(originating_page, expected_chain)
    actual_chain = originating_page.link_chain_without_loop
    assert_equal expected_chain, actual_chain
  end

end
