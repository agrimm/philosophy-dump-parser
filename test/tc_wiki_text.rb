# coding: utf-8
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "test")

require "test/unit"
require "wiki_text"

class TestXmlParsing < Test::Unit::TestCase
  def setup
  end

  def test_parse_wiki_text_with_content
    assert_first_article_is(wiki_text_with_content, "Genese")
  end

  def test_handle_text_non_destructively
    original_text = "{{template}}"
    untouched_text = "{{template}}"
    wiki_text = create_wiki_text(original_text)
    assert_equal original_text, untouched_text, "WikiText is destructive on text"
  end

  def test_parse_wiki_text_without_content
    assert_first_article_is(wiki_text_without_content, nil)
  end

  def test_ignore_hatnotes
    original_text = ":For the manga character, see [[Non target page]]\n\n[[Target page]]"
    assert_first_article_is(original_text, "Target page")
  end

  def test_handle_multiple_spaces
    original_text = "[[Lost        in            space]]"
    assert_first_article_is(original_text, "Lost in space")
  end

  def test_handle_spaces_at_start_and_end
    original_text = "[[ Lost in space  ]]"
    assert_first_article_is(original_text, "Lost in space")
  end

  def test_ignore_text_within_tags
    original_text = '<ref name="multiple">Author, A. (2007). "How to cite references", [[New York]]: McGraw-Hill.</ref> is not [[Sydney]]'
    assert_first_article_is(original_text, "Sydney")
  end

  def assert_first_article_is(text, expected_article)
    wiki_text = WikiText.new(text)
    articles = wiki_text.linked_articles
    actual_first_article = articles.first
    assert_equal expected_article, actual_first_article
  end

  def create_wiki_text(text)
    WikiText.new(text)
  end

  def wiki_text_with_content
    "[[Image:Gutenberg Bible.jpg|thumb|450px|Baibel]]
*[[Genese]] 
*[[Esodo]] 
*[[Iobu]] 
*[[Salamo]] 
*[[Aonega Herevadia]] 
*[[Isaia]] 
*[[Ieremia]] 
*[[Esekiela]] 
*[[Daniela]] 
*[[Mataio]] 
*[[Luka]] 
*[[Ioane]] 
*[[Kara]] 
*[[Roma]] 
*[[1 Korinto]] 
*[[2 Korinto]] 
*[[Efeso]] 
*[[Hadibaia Tauna]] 
*[[1 Tesalonika]] 
*[[2 Tesalonika]] 
*[[1 Timoteo]]
*[[2 Timoteo]]
*[[Heberu]] 
*[[Iamesi]] 
*[[1 Petero]] 
*[[2 Petero]] 
*[[Apokalupo]]

[[Category:Keristani]]

[[af:Bybel]]
[[ar:الكتاب المقدس]]
[[ast:Biblia]]
[[az:Müqəddəs Kitab]]
[[ba:Библия]]
[[bg:Библия]]
[[bi:Baebol]]
[[bm:Bibulu]]
[[bn:বাইবেল]]
[[br:Bibl]]
[[bs:Biblija]]
[[bxr:Библи]]
[[ca:Bíblia]]
[[cdo:Séng-gĭng]]
[[ch:Biblia]]
[[chr:ᎪᏪᎭᎨᏛ]]
[[cs:Bible]]
[[cv:Библи]]
[[cy:Y Beibl]]
[[da:Bibelen]]
[[de:Bibel]]
[[diq:İncile]]
[[dv:ބައިބަލް]]
[[ee:Biblia]]
[[el:Αγία Γραφή]]
[[en:Bible]]
[[eo:Biblio]]
[[es:Biblia]]
[[et:Piibel]]
[[eu:Biblia]]
[[fa:انجیل]]
[[fi:Raamattu]]
[[fj:Ai Vola Tabu]]
[[fr:Bible]]
[[fur:Biblie]]
[[ga:An Bíobla]]
[[gd:Bìoball]]
[[gl:Biblia]]
[[ha:Baibûl]]
[[he:ביבליה]]
[[hi:बाइबिल]]
[[hr:Biblija]]
[[hsb:Biblija]]
[[ht:Bib]]
[[hu:Biblia]]
[[hy:Աստվածաշունչ]]
[[hz:Ombeibela]]
[[ia:Biblia]]
[[id:Alkitab]]
[[ig:Akwụkwọ Nsọ]]
[[ilo:Biblia]]
[[io:Biblo]]
[[is:Biblían]]
[[it:Bibbia]]
[[ja:聖書]]
[[jv:Alkitab]]
[[ka:ბიბლია]]
[[kg:Biblia]]
[[ki:Biblia]]
[[kj:Ombibeli]]
[[kk:Таурат және Інжіл]]
[[kl:Biibili]]
[[ko:성서]]
[[ku:Încîl]]
[[kw:Bibel]]
[[ky:Библия]]
[[la:Biblia]]
[[lad:Biblia]]
[[lb:Bibel]]
[[lg:Baibuli]]
[[li:Biebel]]
[[ln:Biblíya]]
[[lt:Biblija]]
[[lv:Bībele]]
[[mg:Baiboly]]
[[mk:Библија]]
[[ml:ബൈബിള്‍]]
[[mn:Библи]]
[[ms:Kitab Bible]]
[[mt:Bibbja]]
[[na:Bibel]]
[[nds:Bibel]]
[[nds-nl:Biebel]]
[[ne:बाइबल]]
[[ng:Ombimbeli]]
[[nl:Bijbel (christendom)]]
[[nn:Bibelen]]
[[no:Bibelen]]
[[nrm:Bibl'ye]]
[[ny:Baibulo]]
[[oc:Bíblia]]
[[om:Kitaaba]]
[[pa:ਬਾਈਬਲ]]
[[pap:Beibel]]
[[pdc:Biwwel]]
[[pl:Biblia]]
[[pt:Bíblia]]
[[qu:Dyuspa Simin Qillqa]]
[[rn:Bibiliya]]
[[ro:Biblia]]
[[ru:Библия]]
[[ru-sib:Библия]]
[[rw:Bibiliya]]
[[scn:Bibbia cristiana]]
[[sg:Bible]]
[[sh:Biblija]]
[[simple:Bible]]
[[sk:Biblia]]
[[sl:Sveto pismo]]
[[sn:Bhaibheri]]
[[sq:Bibla]]
[[st:Bebele]]
[[su:Alkitab]]
[[sv:Bibeln]]
[[ta:விவிலியம்]]
[[te:బైబిల్]]
[[tet:Bíblia]]
[[tg:Таврот ва Инҷил]]
[[th:คัมภีร์ไบเบิล]]
[[tk:Injil]]
[[tl:Bibliya]]
[[to:Tohitapu]]
[[tpi:Baibel]]
[[tr:Kitab-ı Mukaddes]]
[[tt:İzge yazu]]
[[tw:Twere Kronkron]]
[[ty:Bibilia]]
[[ug:ئىنجىل]]
[[uk:Біблія]]
[[ur:بائبل]]
[[uz:Muqaddas Kitob (Xristian Dinida)]]
[[ve:Bivhili]]
[[vi:Kinh Thánh]]
[[vls:Bybel]]
[[wo:Biibël]]
[[xh:IBhayibhile]]
[[yi:בייבל]]
[[yo:Bíbélì Mimọ]]
[[zh:聖經]]
[[zh-min-nan:Sèng-keng]]
[[zh-yue:聖經]]
[[zu:IBhayibheli]]"
  end

  def wiki_text_without_content
    "<center>
'''<big>This Wikipedia has been closed.  [http://meta.wikimedia.org/wiki/Proposals_for_closing_projects/Closure_of_Hiri_Motu_Wikipedia]</big>''' 

Please visit [[m:Requests for new languages]] if you would like to re-open this project.
</center>"
  end
end
