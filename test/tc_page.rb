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

  def assert_direct_link_to(originating_page, expected_target_page)
    actual_target_page = originating_page.direct_link
    assert_equal expected_target_page, actual_target_page
  end

end
