require 'stringio'
require 'page'

class TestHelperXmlCreation

  def createXmlFile(number_mainspace_pages, number_non_mainspace_pages)
    page_elements = []
    number_mainspace_pages.times do
      page_elements << mainspace_page
    end
    number_non_mainspace_pages.times do
      page_elements << non_mainspace_page
    end
    create_xml_file_given_page_elements(page_elements)
  end

  def create_xml_file_given_page_elements(page_elements)
    file = StringIO.new
    file << xml_start
    page_elements.each do |page_element|
      file << page_element
    end
    file << xml_end
    file.rewind
    file
  end

  def xml_start
    '<mediawiki xmlns="http://www.mediawiki.org/xml/export-0.3/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.mediawiki.org/xml/export-0.3/ http://www.mediawiki.org/xml/export-0.3.xsd" version="0.3" xml:lang="is">
  <siteinfo>
    <sitename>Wikipedia</sitename>
    <base>http://is.wikipedia.org/wiki/Fors%C3%AD%C3%B0a</base>
    <generator>MediaWiki 1.14alpha</generator>
    <case>first-letter</case>
      <namespaces>
      <namespace key="-2">Miðill</namespace>
      <namespace key="-1">Kerfissíða</namespace>
      <namespace key="0" />
      <namespace key="1">Spjall</namespace>
      <namespace key="2">Notandi</namespace>
      <namespace key="3">Notandaspjall</namespace>
      <namespace key="4">Wikipedia</namespace>
      <namespace key="5">Wikipediaspjall</namespace>
      <namespace key="6">Mynd</namespace>
      <namespace key="7">Myndaspjall</namespace>
      <namespace key="8">Melding</namespace>
      <namespace key="9">Meldingarspjall</namespace>
      <namespace key="10">Snið</namespace>
      <namespace key="11">Sniðaspjall</namespace>
      <namespace key="12">Hjálp</namespace>
      <namespace key="13">Hjálparspjall</namespace>
      <namespace key="14">Flokkur</namespace>
      <namespace key="15">Flokkaspjall</namespace>
      <namespace key="100">Gátt</namespace>
      <namespace key="101">Gáttaspjall</namespace>
    </namespaces>
  </siteinfo>'
  end

  def mainspace_page
    generate_mainspace_page({})
  end

  def linked_to_mainspace_page
    generate_mainspace_page({:title_text => linked_to_mainspace_page_title_text})
  end

  def linked_to_mainspace_page_title_text
    "Egill Skallagrímsson"
  end

  def circular_reference_only_mainspace_page
    title_text = generate_random_title_text
    generate_mainspace_page({:title_text => title_text, :mainspace_page_revision_text_text => mainspace_page_revision_text_text_with_one_specified_link(title_text)})
  end

  def generate_pair_of_infinitely_looping_pages
    title_texts = [0,1].map {generate_random_title_text}
    page_revision_text_texts = title_texts.map {|title_text| mainspace_page_revision_text_text_with_one_specified_link(title_text)}
    pages = [0,1].map{|i| generate_mainspace_page({:mainspace_page_revision_text_text => page_revision_text_texts[i], :title_text => title_texts[1-i]}) }
  end

  def generate_random_title_text
    "Random title #{generate_page_id}"
  end

  def generate_mainspace_page(options)
    defaults = {:mainspace_page_revision_text_text => self.mainspace_page_revision_text_text, :title_text=> self.generate_random_title_text}
    options = defaults.merge(options)
    page_id = generate_page_id
    title_text = options[:title_text]
    mainspace_page_revision_text_text = options[:mainspace_page_revision_text_text]
    res = \
"  <page>
    <title>#{title_text}</title>
    <id>#{page_id}</id>
    <revision>
      <id>552134</id>
      <timestamp>2008-09-30T10:04:49Z</timestamp>
      <contributor>
        <username>Þórarinn Friðjónsson</username>
        <id>1506</id>
      </contributor>
      <text xml:space=\"preserve\">#{mainspace_page_revision_text_text}</text>
    </revision>
  </page>
"
  end

  def mainspace_page_revision_text_text
    "'''Íslensk skáld og rithöfundar'''&lt;br&gt;
Íslensk skáld eru æðimörg. Þeirra á meðal eru þessi:

(Flokkun skálda á aldir fer hvorki eftir fæðingarári né dánarári, heldur er miðað við hvenær skáldin voru virkust og gáfu mest út)

== 10. öld ==

*[[Egill Skallagrímsson]]

== 11. öld ==

*[[Sighvatur Þórðarson]]

== 12. öld ==

*[[Einar Skúlason]]

== 13. öld ==

* [[Snorri Sturluson]]

== 16. öld ==
* [[Staðarhóls-Páll]] (Páll Jónsson) ''(d. 1598)''
* [[Einar Sigurðsson í Eydölum]] ''(1539-1626)''

etc. etc."
  end

  def expected_mainspace_page_revision_text_text
    "'''Íslensk skáld og rithöfundar'''<br>
Íslensk skáld eru æðimörg. Þeirra á meðal eru þessi:

(Flokkun skálda á aldir fer hvorki eftir fæðingarári né dánarári, heldur er miðað við hvenær skáldin voru virkust og gáfu mest út)

== 10. öld ==

*[[Egill Skallagrímsson]]

== 11. öld ==

*[[Sighvatur Þórðarson]]

== 12. öld ==

*[[Einar Skúlason]]

== 13. öld ==

* [[Snorri Sturluson]]

== 16. öld ==
* [[Staðarhóls-Páll]] (Páll Jónsson) ''(d. 1598)''
* [[Einar Sigurðsson í Eydölum]] ''(1539-1626)''

etc. etc."
  end

  def mainspace_page_revision_text_text_with_one_specified_link(target)
    "There's only one wikilink, and that's [[#{target}]]. There's a nice [[Image:picture.jpg]], but everything else is [[el:irrelevant]]"
  end

  def non_mainspace_page
    page_id = generate_page_id
    res = \
"  <page>
    <title>Melding:Blockedtext</title>
    <id>#{page_id}</id>
    <restrictions>sysop</restrictions>
    <revision>
      <id>316072</id>
      <timestamp>2007-08-09T18:02:59Z</timestamp>
      <contributor>
        <username>Steinninn</username>
        <id>952</id>
      </contributor>
      <minor />
      <comment>stjórnandi breytt í möppudýr</comment>
      <text xml:space=\"preserve\">Notandanafn þitt eða IP-tala hefur verið bannað af $1.
Ástæðan sem gefin var er eftirfarandi:&lt;br&gt;''$2''&lt;p&gt;Þú getur reynt að hafa samband við $1 eða eitthvað annað
[[Wikipedia:Möppudýr|möppudýr]] til að ræða bannið.

Athugaðu að „Senda þessum notanda tölvupóst“ möguleikinn er óvirkur nema þú hafir skráð gilt netfang í [[Kerfissíða:Preferences|notandastillingum þínum]].

IP-talan þín er $3. Vinsamlegast taktu það fram í fyrirspurnum þínum.</text>
    </revision>
  </page>"
  end

  def xml_end
    res = "</mediawiki>"
  end

  def generate_page_id
    @previous_page_id = @previous_page_id || 2
    @previous_page_id += 1
    return @previous_page_id
  end
end


class TestHelperPageCreation
  def initialize
    @test_helper_xml_creation_object = TestHelperXmlCreation.new
  end

  def create_page(options = {})
    defaults = {:title => random_title, :text=> random_text}
    options = defaults.merge(options)
    return Page.new(options[:title], options[:text])
  end

  def random_title
    @test_helper_xml_creation_object.generate_random_title_text
  end

  def random_text
    @test_helper_xml_creation_object.expected_mainspace_page_revision_text_text
  end

  def create_page_linking_to_pages(page_titles)
    text = page_titles.map{|page_title| "[[#{page_title}]] and "}.join
    create_page({:text => text})
  end
end

