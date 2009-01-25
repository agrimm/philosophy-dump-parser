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

  def test_parse_article_id
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    mainspace_page_xml_element = test_helper_xml_creation_object.generate_mainspace_page({:page_id => 42})
    second_mainspace_page_xml_element =  test_helper_xml_creation_object.generate_mainspace_page({:page_id => 67})
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements([mainspace_page_xml_element, second_mainspace_page_xml_element])
    page_xml_parser = PageXmlParser.new(xml_file)
    pages = page_xml_parser.mainspace_pages
    assert_has_page_id pages[0], 42
    assert_has_page_id pages[1], 67
  end

  def test_reject_zero_page_id
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    mainspace_page_xml_element = test_helper_xml_creation_object.generate_mainspace_page({:page_id => 0})
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements([mainspace_page_xml_element])
    assert_raise(RuntimeError) do
      page_xml_parser = PageXmlParser.new(xml_file)
      page_xml_parser.mainspace_pages
    end
  end

  def test_reject_negative_page_id
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    mainspace_page_xml_element = test_helper_xml_creation_object.generate_mainspace_page({:page_id => -1})
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements([mainspace_page_xml_element])
    assert_raise(RuntimeError) do
      page_xml_parser = PageXmlParser.new(xml_file)
      page_xml_parser.mainspace_pages
    end
  end

  def test_reject_non_numeric_page_id
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    mainspace_page_xml_element = test_helper_xml_creation_object.generate_mainspace_page({:page_id => "text"})
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements([mainspace_page_xml_element])
    assert_raise(ArgumentError) do
      page_xml_parser = PageXmlParser.new(xml_file)
      page_xml_parser.mainspace_pages
    end
  end

  def test_reject_octal_page_id
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    mainspace_page_xml_element = test_helper_xml_creation_object.generate_mainspace_page({:page_id => "07"})
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements([mainspace_page_xml_element])
    assert_raise(RuntimeError) do
      page_xml_parser = PageXmlParser.new(xml_file)
      page_xml_parser.mainspace_pages
    end
  end


  def dont_test_get_text_contents
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

  def test_parse_out_quotations
    quotation_containing_title = "&quot;Weird Al&quot; Yankovic"
    quotation_exorcised_title = "\"Weird Al\" Yankovic"
    assert_parsing_works_for_title(quotation_exorcised_title, quotation_containing_title)
  end

  def test_parse_out_ampersands
    ampersand_containing_title = "Command &amp; Conquer"
    ampersand_exorcised_title = "Command & Conquer"
    assert_parsing_works_for_title(ampersand_exorcised_title, ampersand_containing_title)
  end

  #Turned off because current use of libxml is noisy on one test and unfortunately fails two others
  def dont_test_aardvark_recognize_illegal_xml #Needs other tests to clean up after itself
    illegal_titles = ["Less than <"]
    illegal_titles_not_detected = ["Greater than >", "Quotation \""]
    illegal_titles.each {|illegal_title| assert_illegal_xml_detected(illegal_title)}
  end


  #No testing here for less than signs or greater than signs. They aren't allowed in article titles.
  # http://en.wikipedia.org/wiki/Wikipedia:Naming_conventions_(technical_restrictions)#Characters_totally_forbidden_in_page_titles
  #However, test_get_text_contents tests less than and greater than in page text.

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

  def assert_parsing_works_for_title(parsed_title, unparsed_title)
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    pages = create_pages_given_page_elements([test_helper_xml_creation_object.generate_mainspace_page({:title_text => unparsed_title})])
    page = pages.first
    assert_equal parsed_title, page.title, "Some characters weren't parsed out"
  end

  def assert_illegal_xml_detected(illegal_xml)
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    assert_raise(RuntimeError) do
      pages = create_pages_given_page_elements([test_helper_xml_creation_object.generate_mainspace_page({:title_text => illegal_xml})])
    end
  end

  def assert_has_page_id(page, expected_id)
    assert_equal expected_id, page.page_id
  end

  def create_pages_given_page_elements(page_elements)
    test_helper_xml_creation_object = TestHelperXmlCreation.new
    xml_file = test_helper_xml_creation_object.create_xml_file_given_page_elements(page_elements)
    page_xml_parser = PageXmlParser.new(xml_file)
    mainspace_pages = page_xml_parser.mainspace_pages
    mainspace_pages
  end

end
