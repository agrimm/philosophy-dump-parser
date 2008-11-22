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

  def assert_expected_size(expected_size, array)
    assert_equal expected_size, array.size
  end
end
