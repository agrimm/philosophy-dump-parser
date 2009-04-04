$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "test")

require "test/unit"
#require "repository"
require "page"

class TestRepositoryHandler < Test::Unit::TestCase

  def test_truth
    assert true
  end

  def dont_test_allow_nilling_of_titles
    options = {:title_representation => :none}
    repository_handler = RepositoryParser.new(options)
    page = repository_handler.new_page_if_valid(*boring_page_options)
    assert_page_has_none_title_representation(page)
  end

  def boring_page_options
     ["Title", 1, "Text", {}]
  end

  def assert_page_has_none_title_representation(page)
    assert page.title_string.include?("Page number")
  end
end
