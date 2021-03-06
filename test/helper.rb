require "helper_xml_creation"

class MockRepository
  attr_accessor :real_repository

  def initialize
    @real_repository = Repository.new_with_configuration({}) #yeah, I could use inheritance
  end

  def page_id
    @page_id ||= 0
    @page_id += 1
    @page_id
  end

  def new_page_if_valid(title)
    return @real_repository.new_page_if_valid(title, page_id)
  end
end

class TestHelperPageCreation
  def initialize
    @test_helper_xml_creation_object = TestHelperXmlCreation.new
    @repository = MockRepository.new
  end

  def build_total_backlink_counts
    @repository.real_repository.build_total_backlink_counts
  end

  def repository_pages
    @repository.real_repository.pages(true)
  end

  def create_page(options = {})
    raise "missing or not allowed keys included: #{options.keys.inspect}" unless options.keys == [:title]
    return @repository.new_page_if_valid(options[:title])
  end

  def random_title
    @test_helper_xml_creation_object.generate_random_title_text
  end

  #Create several pages with the specified links
  def create_network(titles_and_links)
    titles_and_links = titles_and_links.map do |title, links|
      title = random_title if title.nil?
      [title, links]
    end
    titles_and_texts = titles_and_links.map do |title, links|
      text = links.map{|link| "[[#{link}]]"}.join(" and ") + "."
      [title, text]
    end
    create_network_with_wiki_text(titles_and_texts)
  end

  def create_network_with_wiki_text(titles_and_wiki_texts)
    titles = titles_and_wiki_texts.map{|title, wiki_text| title}
    create_pages(titles)
    add_to_pages_some_texts(titles_and_wiki_texts)
    build_total_backlink_counts
    repository_pages
  end

  def create_pages(titles)
    @repository.real_repository.within_transactions(100) do
      titles.each do |title|
        create_page({:title => title})
      end
    end
  end

  def add_to_pages_some_texts(titles_and_texts)
    @repository.real_repository.within_transactions(100) do
      titles_and_texts.each do |title, text|
        @repository.real_repository.add_to_page_by_title_some_text(title, text)
      end
    end
  end

  def create_repository_given_network_description(network_description)
    create_repository_given_network_description_and_configuration(network_description, {})
  end

  def create_repository_given_network_description_and_configuration(network_description, configuration)
    @repository.real_repository = Repository.new_with_configuration(configuration)
    create_network(network_description)
    repository = @repository.real_repository
    repository
  end

end

