$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "test")


require "test/unit"

require "helper_xml_creation"
require "page_xml_parser"

class TestXmlParsing < Test::Unit::TestCase
  def setup
  end

  def test_count_mainspace_pages
    expected_number_mainspace_pages = 2
    number_non_mainspace_pages = 3
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    page_xml_file = test_helper_xml_creation_object.createXmlFile(expected_number_mainspace_pages, number_non_mainspace_pages)
    page_xml_parser = PageXmlParser.new(page_xml_file)
    mainspace_pages = page_xml_parser.mainspace_pages
    assert_expected_size expected_number_mainspace_pages, mainspace_pages
  end

  def test_get_text_contents
    expected_number_mainspace_pages = 2
    number_non_mainspace_pages = 3
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    page_xml_file = test_helper_xml_creation_object.createXmlFile(expected_number_mainspace_pages, number_non_mainspace_pages)
    page_xml_parser = PageXmlParser.new(page_xml_file)
    mainspace_pages = page_xml_parser.mainspace_pages
    page = mainspace_pages.first
    expected_text = test_helper_xml_creation_object.expected_mainspace_page_revision_text_text
    actual_text = page.text
    assert_equal expected_text, actual_text
  end

  def test_find_linked_article
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements([test_helper_xml_creation_object.mainspace_page, test_helper_xml_creation_object.linked_to_mainspace_page])
    page_xml_parser = PageXmlParser.new(xml_file)
    mainspace_pages = page_xml_parser.mainspace_pages
    first_page = mainspace_pages[0]
    linked_to_page = mainspace_pages[1]
    assert_direct_link_to(first_page, linked_to_page)
  end

  def test_dont_find_yourself
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements([test_helper_xml_creation_object.circular_reference_only_mainspace_page])
    page_xml_parser = PageXmlParser.new(xml_file)
    mainspace_pages = page_xml_parser.mainspace_pages
    page = mainspace_pages.first
    assert_direct_link_to(page, nil)
  end

  def test_link_chain_string_with_deadend
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements([test_helper_xml_creation_object.mainspace_page, test_helper_xml_creation_object.linked_to_mainspace_page])
    page_xml_parser = PageXmlParser.new(xml_file)
    mainspace_pages = page_xml_parser.mainspace_pages
    assert_equal "#{mainspace_pages[0].title_string} links to #{mainspace_pages[1].title_string}, which links to nothing.", mainspace_pages[0].link_chain_string
  end

  def test_link_chain_can_handle_infinite_loop
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements(test_helper_xml_creation_object.generate_pair_of_infinitely_looping_pages)
    page_xml_parser = PageXmlParser.new(xml_file)
    mainspace_pages = page_xml_parser.mainspace_pages
    assert_equal "#{mainspace_pages[0].title_string} links to #{mainspace_pages[1].title_string}, which links to previously encountered #{mainspace_pages[0].title_string}.", mainspace_pages[0].link_chain_string
  end


  def assert_expected_size(expected_size, array)
    assert_equal expected_size, array.size
  end

  def assert_direct_link_to(originating_page, expected_target_page)
    actual_target_page = originating_page.direct_link
    assert_equal expected_target_page, actual_target_page
  end

end
