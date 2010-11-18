require 'test_helper'

class SnippetTest < ActiveSupport::TestCase

  test "snippet is saved" do 
    assert Snippet.new(:content=>"puts %{hola mundo}", :language=>"ruby", :user=>users(:one), :private=>true)
  end

  test "snippet is saved non private by default" do 

    s = Snippet.new :content=>"while(1){printf('hola')}", :language=>"c", :user=>users(:one)

    assert s.save
    assert_equal false, s.private
  end

  test "snippet has an anonymous author by default" do

    s = Snippet.new :content=>"while(1){printf('hola')}", :language=>"c" 

    assert s.save
    assert_nil s.user
  end

  test "snippet is stored with the default language" do 
    s = Snippet.new :content=>"print 'hola mundo'", :user=>users(:one)

    assert s.save
    assert_equal Snippet::DEFAULT_LANGUAGE, s.language
  end

  test "snippet is split into sections with shebang syntax" do 

    #la sintaxis #shebang: una línea con un octothorpe+shebang (##!), uno O MAS espacios, y el nombre de un lenguaje soportado
    #seguido de lo que sea, se debería ignorar

    #PRUEBA 1: reconoce secciones con #shebang, a pesar del espacio en blanco
    content ="##!   ruby\nputs %{o hai}\n##! html   \n <h1>OH, HAI</h1>"
    s = Snippet.new :content=>content, :language=>"ruby", :user=>users(:two)
    
    assert s.save
    sections = s.get_sections
    assert_equal 2, sections.size
    assert_instance_of Array, sections
    assert_instance_of Hash, sections.first

    #debe producir un arreglo de hashes de la forma
    #[{:language=>"ruby", :content=>"puts %{o hai}"}, {:language=>"html", :content=>"<h1>OH HAI</h1>"}
    assert_equal "ruby", sections.first[:language]
    assert_equal "html",  sections.last[:language]
    
    #la línea de shebang NO tiene que estar en el contenido final
    assert_nil sections.first[:content]["#! ruby"]
    assert_nil sections.last[:content]["#! html"]

    #tiene que haber encontrado el contenido bien
    assert_not_nil sections.first[:content]["puts %{o hai}"]
    assert_not_nil sections.last[:content]["<h1>OH, HAI</h1>"]
  end

  test "shebang-ed languages in snippets have precedence over original language when displayed" do
    #PRUEBA 2:
    #shebang tiene precedencia sobre el lenguaje original al seccionar (pero no al guardar)
    t = Snippet.new :content=>"##! java\nnew Map(){{put('mind', 'blown')}};", :language=>"yaml"
    
    sections = t.get_sections
    assert t.save
    assert_equal "yaml", t.language
    assert_equal 1, sections.size
    assert_equal "java", sections.first[:language]
    assert_not_nil sections.first[:content]["'mind', 'blown'"]
  end

  test "shebang only applies at the beginning of lines" do
    #PRUEBA 3: 
    #no debería partir en secciones si hay un shebang en medio de una línea:
    r = Snippet.new :content=>"and you write it like this: `##! python` and baam!", :language=>"ocaml"
    
    #si sólo hay una sección, retornar el snippet original:
    sections = r.get_sections
    assert_equal 1, sections.size
    assert_equal "ocaml", sections.first[:language]
    #como no es un verdadero #shebang, no debería quitarse:
    assert_not_nil sections.first[:content]["##! python` and"]
  end
  
  #en una línea con shebang, sólo el primer string se debería considerar el lenguaje, lo demás, no
  test "the shebanged language considered is the first string in the shebanged line" do 
    r = Snippet.new :content => "##! python ocaml c, as\n print[ e for e in range(10)]", :language=>"js"

    sections = r.get_sections
    assert_equal 1, sections.size
    assert_equal "python", sections.first[:language]
  end

  test "snippet is versioned" do end


  test "snippet versions are diffable" do end
end