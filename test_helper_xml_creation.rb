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
    <title>Finnland</title>
    <id>#{page_id}</id>
    <revision>
      <id>572242</id>
      <timestamp>2008-11-07T23:59:21Z</timestamp>
      <contributor>
        <username>Zorrobot</username>
        <id>2956</id>
      </contributor>
      <minor />
      <comment>robot  Breyti: [[new:फिनल्यान्ड]]</comment>
      <text xml:space=\"preserve\">{{Land
|nafn_á_frummáli=Suomen tasavalta&lt;br /&gt;Republiken Finland&lt;br /&gt;Lýðveldið Finnland
|nafn_í_eignarfalli=Finnlands
|fáni=Flag of Finland.svg
|skjaldarmerki=Coat of arms of Finland.svg
etc. etc.</text>
    </revision>
  </page>"
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

