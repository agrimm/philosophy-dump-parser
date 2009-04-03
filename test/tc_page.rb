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

    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ [nil, [lowercase_title]], [uppercase_title, []] ]
    original_page, linked_to_page = test_helper_page_creation_object.create_network(network)

    assert_direct_link_to original_page, linked_to_page
  end

  def test_dont_handle_empty_titles
    test_helper_page_creation_object = TestHelperPageCreation.new
    assert_raise(TitleNilError) do
      page = test_helper_page_creation_object.create_page({:title=>nil, :article_list=>{}})
    end
  end

  def test_page_id_available
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ [nil, []] ]
    page, = test_helper_page_creation_object.create_network(network)
    assert_has_page_id page, 1
  end

  #To do: move this test into tc_wiki_text
  def test_ignore_hatnotes
    test_helper_page_creation_object = TestHelperPageCreation.new

    original_page_details = ({:title => "Artemis", :text => ":For the manga character, see [[Non target page]]\n\n[[Target page]]"})
    details = [original_page_details, {:title=>"Non target page"}, {:title => "Target page"}]
    repository = test_helper_page_creation_object.create_repository_given_titles_and_text(details)
    original_page, target_page = repository.pages[0], repository.pages[2]

    assert_direct_link_to(original_page, target_page)
  end

#Some testing exists in tc_page_xml_parsing.rb

  def test_link_chain_without_loop
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Philosophy page", ["Looping page"]], ["Looping page", ["Philosophy page"]], [nil, ["Philosophy page"]] ]
    philosophy_page, looping_page, general_page = test_helper_page_creation_object.create_network(network)
    assert_link_chain_without_loop_matches general_page, [general_page, philosophy_page]
    assert_link_chain_without_loop_matches philosophy_page, [philosophy_page]
    assert_link_chain_without_loop_matches looping_page, [looping_page] #This feels wrong
  end

  def dont_test_asking_for_link_information_without_building_links_throws_exception
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Philosophy page", ["Looping page"]], ["Looping page", ["Philosophy page"]], [nil, ["Philosophy page"]] ]
    philosophy_page, looping_page, general_page = test_helper_page_creation_object.create_network(network)
    assert_raise(RuntimeError) {philosophy_page.total_backlink_count_string}
  end

  def test_backlinks
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Target page", [] ], [nil, ["Target page"]] ]
    target_page, linking_page = test_helper_page_creation_object.create_network(network)
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

    assert_direct_link_to(page, nil)
    assert_link_chain_without_loop_matches(page, [page])
  end

  def test_backlink_merge_count_for_direct_backlinks
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Merging page", []], [nil, ["merging page"]], [nil, ["merging page"]] ]
    pages = test_helper_page_creation_object.create_network(network)
    merging_page = pages.first
    normal_page = pages[1]
    assert_equal 1, merging_page.backlink_merge_count, "Can't produce the right answer for a page merging direct backlinks"
    assert_equal 0, normal_page.backlink_merge_count, "Can't produce the right answer for a page with no backlinks"
  end

  def test_backlink_merge_count_for_indirect_backlinks
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Philosophy page", []], ["Popular page 1", ["philosophy page"]], ["Popular page 2", ["philosophy page"]] ]
    network += [[nil, ["popular page 1"]]] * 5
    network += [[nil, ["popular page 2"]]] * 10
    pages = test_helper_page_creation_object.create_network(network)
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
    network = [ ["Philosophy page", []], ["Popular page 1", ["philosophy page"]] ]
    network += [[nil, ["popular page 1"]]] * 5
    pages = test_helper_page_creation_object.create_network(network)
    philosophy_page = pages.first
    assert_equal 0, philosophy_page.backlink_merge_count, "Can't produce the right answer for a page that merely continues a chain without merging anything"
  end

  def test_backlink_merge_count_string
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Philosophy page", []], ["Popular page 1", ["philosophy page"]], ["Popular page 2", ["philosophy page"]] ]
    network += [[nil, ["popular page 1"]]] * 5
    network += [[nil, ["popular page 2"]]] * 10
    pages = test_helper_page_creation_object.create_network(network)
    philosophy_page = pages.first
    philosophy_page_expected_string = "Philosophy page has merged 6 backlinks"
    philosophy_page_actual_string = philosophy_page.backlink_merge_count_string
    assert_equal philosophy_page_expected_string, philosophy_page_actual_string

    mergeless_page = pages.last
    mergeless_page_expected_string = ""
    mergeless_page_actual_string = mergeless_page.backlink_merge_count_string
    assert_equal mergeless_page_expected_string, mergeless_page_actual_string, "Mergeless page doesn't have an empty string"
  end

  def test_dont_throw_an_exception_with_capitalization_issues
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Acropolis of Athens", ["Acropolis of Athens", "Acropolis"]], ["Acropolis of athens", []], ["Acropolis", []] ]
    pages = nil
    assert_nothing_raised do
      pages = test_helper_page_creation_object.create_network(network)
    end
  end

  def test_dont_throw_an_exception_with_capitalization_issues_for_a_self_link
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [ ["Acropolis of Athens", ["Acropolis of Athens"]]]
    assert_nothing_raised do
      pages = test_helper_page_creation_object.create_network(network)
    end
  end

  def test_link_to_page_with_capitalization_in_second_word
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [[nil, ["the Moon"]], ["The Moon", []]]
    pages = test_helper_page_creation_object.create_network(network)
    assert_direct_link_to pages.first, pages[1]
  end

  def test_reject_titles_starting_lowercase
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [["lowercase",[]]]
    assert_raise(RuntimeError) {pages = test_helper_page_creation_object.create_network(network)}
  end

  def test_handle_empty_wikilinks
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [[nil,[""]]]
    assert_nothing_raised do
      pages = test_helper_page_creation_object.create_network(network)
    end
  end

  def test_reject_self_links_even_if_lower_case
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [["Page One", ["page One", "page Two"]], ["Page Two", []]]
    pages = test_helper_page_creation_object.create_network(network)
    assert_not_nil pages[0].direct_link, "shortern_link_list_if_possible shortened the list to an invalid link"
    assert_direct_link_to pages[0], pages[1]
  end

  def test_accept_link_that_seems_similar_to_self_link
    test_helper_page_creation_object = TestHelperPageCreation.new
    network = [["Event horizon", ["Event Horizon"]], ["Event Horizon", []]]
    pages = test_helper_page_creation_object.create_network(network)
    assert_direct_link_to pages[0], pages[1], "Link to similar title does not work."
  end

  def assert_has_page_id(page, expected_id)
    assert_equal expected_id, page.page_id
  end

  def assert_direct_link_to(originating_page, expected_target_page, message = nil)
    actual_target_page = originating_page.direct_link
    assert_equal expected_target_page, actual_target_page, message
  end

  def assert_link_chain_without_loop_matches(originating_page, expected_chain)
    actual_chain = originating_page.link_chain_without_loop
    assert_equal expected_chain, actual_chain
  end

  def assert_page_title_string_equal(page, expected_title_string, message=nil)
    assert_equal expected_title_string, page.title_string, message
  end

end
