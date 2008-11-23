require 'stringio'

class TestHelperXmlCreation

  def createXmlFile(number_mainspace_pages, number_non_mainspace_pages)
    file = StringIO.new
    file << xml_start
    number_mainspace_pages.times do
      file << mainspace_page
    end
    number_non_mainspace_pages.times do
      file << non_mainspace_page
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
    page_id = generate_page_id
    res = \
"  <page>
    <title>Íslensk skáld</title>
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

