# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

context "Site" do
  setup do
    @wiki = Stinker::Site.new(testpath("examples/lotr.git") )
  end

  test "repo path" do
    assert_equal testpath("examples/lotr.git"), @wiki.path
  end

  test "detect not nanoc" do
    assert_equal false, @wiki.nanoc?
  end

  test "git repo" do
    assert_equal Grit::Repo, @wiki.repo.class
    assert @wiki.exist?
  end

  test "shows paginated log with no page" do
    Stinker::Site.per_page = 3
    commits = @wiki.repo.commits[0..2].map { |x| x.id }
    assert_equal commits, @wiki.log.map { |c| c.id }
  end

  test "shows paginated log with 1st page" do
    Stinker::Site.per_page = 3
    commits = @wiki.repo.commits[0..2].map { |x| x.id }
    assert_equal commits, @wiki.log(:page => 1).map { |c| c.id }
  end

  test "shows paginated log with next page" do
    Stinker::Site.per_page = 3
    commits = @wiki.repo.commits[3..5].map { |x| x.id }
    assert_equal commits, @wiki.log(:page => 2).map { |c| c.id }
  end

  test "list pages" do
    pages = @wiki.pages
    assert_equal \
      %w(Bilbo-Baggins.md Eye-Of-Sauron.md Home.textile My-Precious.md Stinker.md),
      pages.map { |p| p.filename }.sort
  end

  test "counts pages" do
    assert_equal 5, @wiki.size
  end

  test "text_data" do
    wiki = Stinker::Site.new(testpath("examples/yubiwa.git"))
    if String.instance_methods.include?(:encoding)
      utf8 = wiki.page("strider").text_data
      assert_equal Encoding::UTF_8, utf8.encoding
      sjis = wiki.page("sjis").text_data(Encoding::SHIFT_JIS)
      assert_equal Encoding::SHIFT_JIS, sjis.encoding
    else
      page = wiki.page("strider")
      assert_equal page.raw_data, page.text_data
    end
  end

  test "gets reverse diff" do
    diff = @wiki.full_reverse_diff('a8ad3c09dd842a3517085bfadd37718856dee813')
    assert_match "b/Mordor/_Sidebar.md", diff
    assert_match "b/_Sidebar.md", diff
  end

  test "gets reverse diff for a page" do
    diff  = @wiki.full_reverse_diff_for('_Sidebar.md', 'a8ad3c09dd842a3517085bfadd37718856dee813')
    regex = /b\/Mordor\/\_Sidebar\.md/
    assert_match    "b/_Sidebar.md", diff
    assert_no_match regex, diff
  end
end

context "Site page previewing" do
  setup do
    @path = testpath("examples/lotr.git")
    @wiki = Stinker::Site.new(@path)
  end

  test "preview_page" do
    page = @wiki.preview_page("Test", "# Bilbo", :markdown)
    assert_equal "# Bilbo", page.raw_data
    assert_equal "<h1>Bilbo</h1>\n", page.formatted_data
    assert_equal "Test.md", page.filename
    assert_equal "Test", page.name
  end

  test "site_config loaded" do
    assert_equal({"site_name" => "Lord of the Rings"}, @wiki.site_config)
  end
end

context "Site config" do
   setup do
    @path = testpath("examples/config.git")
    @wiki = Stinker::Site.new(@path)
  end

  test "page_file_dir" do
    assert_equal "content", @wiki.page_file_dir
  end

  test "content_types" do
    assert_equal({"page" => {"subtitle" => 'text'}}, @wiki.content_types)
  end
end

context "Wiki page writing" do
  setup do
    @path = testpath("examples/test.git")
    FileUtils.rm_rf(@path)
    Grit::Repo.init_bare(@path)
    @wiki = Stinker::Site.new(@path, {:content_types => {:page => [:title, :baz]}})
  end

  test "detect nanoc" do
    assert_equal false, @wiki.nanoc?
    @wiki.write_file('Rules', '', commit_details)
    assert_equal true, @wiki.nanoc?
  end


  test "write_page" do
    cd = commit_details
    @wiki.write_page("Gollum", :markdown, "# Gollum", cd)
    assert_equal 1, @wiki.repo.commits.size
    assert_equal cd[:message], @wiki.repo.commits.first.message
    assert_equal cd[:name], @wiki.repo.commits.first.author.name
    assert_equal cd[:email], @wiki.repo.commits.first.author.email
    assert @wiki.page("Gollum")

    @wiki.write_page("Bilbo", :markdown, "# Bilbo", commit_details)
    assert_equal 2, @wiki.repo.commits.size
    assert @wiki.page("Bilbo")
    assert @wiki.page("Gollum")
  end

  test "write_page_with_meta" do
    cd = commit_details
    @wiki.write_page_with_meta("Gollum", :markdown, "# Gollum", {'title' => 'foobar'}, cd)
    assert_equal 1, @wiki.repo.commits.size
    assert @wiki.page("Gollum")
    assert_equal "foobar", @wiki.page("Gollum").title

    my_meta = {'title' => 'foo', 'bar'=> 'bar'}
    @wiki.write_page_with_meta("Bilbo", :markdown, "# Bilbo", my_meta, commit_details)
    assert_equal 2, @wiki.repo.commits.size
    assert @wiki.page("Bilbo")
    assert @wiki.page("Gollum")
    assert_equal 'foo', @wiki.page("Bilbo").title
    assert_equal my_meta, @wiki.page("Bilbo").meta_data
  end

  test "content_type meta" do
    assert_equal [:title, :baz], @wiki.content_types[:page]
  end

  

  test "is not allowed to overwrite file" do

    @wiki.write_page("Abc-Def", :markdown, "# Gollum", commit_details)
    @wiki.write_page("bob/dole", :markdown, "# Gollum", commit_details)
    assert_raises Stinker::DuplicatePageError do
      @wiki.write_page("Abc Def", :textile,  "# Gollum", commit_details)
    end
    assert_raises Stinker::DuplicatePageError do
      @wiki.write_page("bob/dole", :textile,  "# Gollum", commit_details)
    end
    assert_raises Stinker::DuplicatePageError do
      @wiki.write_page("BOB/dole", :textile,  "# Gollum", commit_details)
    end
    assert_raises Stinker::DuplicatePageError do
      @wiki.write_page("/bob/dole", :textile,  "# Gollum", commit_details)
    end
    assert_nothing_raised do
      @wiki.write_page("Dole", :textile,  "# Gollum", commit_details)

    end
  end

  test "is able do differentiate similar pages in nested dirs" do
    @wiki.write_page("bar", :markdown, "# Gollum", commit_details)
    assert_nothing_raised do
      @wiki.write_page("foo/bar", :markdown, "# Gollum", commit_details)
      @wiki.write_page("baz/bar", :markdown, "# Gollum", commit_details)
    end

    page3 = @wiki.page('bar').path
    page1 = @wiki.page('foo/bar').path
    page2 = @wiki.page('baz/bar').path
    assert_not_equal page1, page2
    assert_not_equal page2, page3
    assert_not_equal page1, page3
  end

  test "is able to give nested dir in name if duplicates" do
    @wiki.write_page("quux", :markdown, "# Gollum", commit_details)
    @wiki.write_page("nest1/quux", :markdown, "# Gollum", commit_details)
    @wiki.write_page("nest2/quux", :markdown, "# Gollum", commit_details)
    page3 = @wiki.page('quux').name
    page1 = @wiki.page('nest1/quux').name
    page2 = @wiki.page('nest2/quux').name
    assert_equal 'quux', page3
    assert_equal 'nest1/quux', page1
    assert_equal 'nest2/quux', page2
  end

  test "is allowed to have similar filenames if not in same dir" do
    @wiki.write_page("Abc/Def", :markdown, "# Gollum", commit_details)
    assert_nothing_raised  do
      @wiki.write_page("Def/Def", :markdown,  "# Gollum", commit_details)
      @wiki.write_page("Abc-Def", :markdown,  "# Gollum", commit_details)
    end
  end
  

  test "update_page" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    page = @wiki.page("Gollum")
    cd = commit_details
    @wiki.update_page(page, page.name, :markdown, "# Gollum2", cd)

    assert_equal 2, @wiki.repo.commits.size
    assert_equal "# Gollum2", @wiki.page("Gollum").raw_data
    assert_equal cd[:message], @wiki.repo.commits.first.message
    assert_equal cd[:name], @wiki.repo.commits.first.author.name
    assert_equal cd[:email], @wiki.repo.commits.first.author.email
  end

  test "update_page with meta" do
    meta = {'title' => 'Gollum', 'foo' => 'bar'}
    @wiki.write_page_with_meta("Gollum", :markdown, "# Gollum", meta, commit_details)

    page = @wiki.page("Gollum")
    assert_equal meta, page.meta_data
    cd = commit_details
    new_meta = {'meta' => true, 'title' => 'Gollum2'}
    @wiki.update_page_with_meta(page, page.name, :markdown, "# Gollum2", new_meta, cd)

    page = @wiki.page("Gollum")
    assert_equal 2, @wiki.repo.commits.size
    assert_equal "# Gollum2", @wiki.page("Gollum").raw_text_data
    assert_equal meta.merge(new_meta), page.meta_data
  end

  test "update_page preserves meta if exists " do
    meta = {'title' => 'Gollum', 'foo' => 'bar'}
    @wiki.write_page_with_meta("Gollum", :markdown, "# Gollum", meta, commit_details)

    page = @wiki.page("Gollum")
    assert_equal meta, page.meta_data
    cd = commit_details
    @wiki.update_page(page, page.name, :markdown, "# Gollum2" , cd)

    page = @wiki.page("Gollum")
    assert_equal 2, @wiki.repo.commits.size
    assert_equal "# Gollum2", @wiki.page("Gollum").raw_text_data
    assert_equal cd[:message], @wiki.repo.commits.first.message
    assert_equal cd[:name], @wiki.repo.commits.first.author.name
    assert_equal cd[:email], @wiki.repo.commits.first.author.email
    assert_equal meta, page.meta_data
  end


  test "update page with format change" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    assert_equal :markdown, @wiki.page("Gollum").format

    page = @wiki.page("Gollum")
    @wiki.update_page(page, page.name, :textile, "h1. Gollum", commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_equal :textile, @wiki.page("Gollum").format
    assert_equal "h1. Gollum", @wiki.page("Gollum").raw_data
  end

  test "update page with name change" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    assert_equal :markdown, @wiki.page("Gollum").format

    page = @wiki.page("Gollum")
    @wiki.update_page(page, 'Smeagol', :markdown, "h1. Gollum", commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_equal "h1. Gollum", @wiki.page("Smeagol").raw_data
  end

  test "update page with name change and folder change" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    assert_equal :markdown, @wiki.page("Gollum").format

    page = @wiki.page("Gollum")
    @wiki.update_page(page, 'Foobar/Gollum', :markdown, "h1. Gollum", commit_details)
    page = @wiki.page("Gollum")
    @wiki.update_page(page, 'Baz/Smeagol', :markdown, "h1. Gollum", commit_details)
    
    page = @wiki.page("Smeagol")
    assert_equal 3, @wiki.repo.commits.size
    assert_equal "h1. Gollum", @wiki.page("Smeagol").raw_data
    assert_equal 'baz/Smeagol.md', page.path
  end

  test "update page with name and format change" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    assert_equal :markdown, @wiki.page("Gollum").format

    page = @wiki.page("Gollum")
    @wiki.update_page(page, 'Smeagol', :textile, "h1. Gollum", commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_equal :textile, @wiki.page("Smeagol").format
    assert_equal "h1. Gollum", @wiki.page("Smeagol").raw_data
  end

  test "update nested page with format change" do
    index = @wiki.repo.index
    index.add("lotr/Gollum.md", "# Gollum")
    index.commit("Add nested page")

    page = @wiki.page("Gollum")
    assert_equal :markdown, @wiki.page("Gollum").format
    @wiki.update_page(page, page.name, :textile, "h1. Gollum", commit_details)

    page = @wiki.page("Gollum")
    assert_equal "lotr/Gollum.textile", page.path
    assert_equal :textile, page.format
    assert_equal "h1. Gollum", page.raw_data

    page2 = @wiki.page("lotr/Gollum")
    assert_equal page2.path, page.path
  end

  test "delete root page" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)

    page = @wiki.page("Gollum")
    @wiki.delete_page(page, commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_nil @wiki.page("Gollum")
  end

  test "delete nested page" do
    index = @wiki.repo.index
    index.add("greek/Bilbo-Baggins.md", "hi")
    index.add("Gollum.md", "hi")
    index.commit("Add alpha.jpg")

    page = @wiki.page("Bilbo-Baggins")
    assert page
    @wiki.delete_page(page, commit_details)

    assert_equal 2, @wiki.repo.commits.size
    assert_nil @wiki.page("Bilbo-Baggins")

    assert @wiki.page("Gollum")
  end

  teardown do
    FileUtils.rm_r(File.join(File.dirname(__FILE__), *%w[examples test.git]))
  end
end

context "Wiki sync with working directory" do
  setup do
    @path = testpath('examples/wdtest')
    Grit::Repo.init(@path)
    @wiki = Stinker::Site.new(@path)
  end

  test "write a page" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    assert_equal "Hi", File.read(File.join(@path, "New-Page.md"))
  end

  test "update a page with same name and format" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.update_page(page, page.name, page.format, "Bye", commit_details)
    assert_equal "Bye", File.read(File.join(@path, "New-Page.md"))
  end

  test "update a page with different name and same format" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.update_page(page, "New Page 2", page.format, "Bye", commit_details)
    assert_equal "Bye", File.read(File.join(@path, "New-Page-2.md"))
    assert !File.exist?(File.join(@path, "New-Page.md"))
  end

  test "update a page with same name and different format" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.update_page(page, page.name, :textile, "Bye", commit_details)
    assert_equal "Bye", File.read(File.join(@path, "New-Page.textile"))
    assert !File.exist?(File.join(@path, "New-Page.md"))
  end

  test "update a page with different name and different format" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.update_page(page, "New Page 2", :textile, "Bye", commit_details)
    assert_equal "Bye", File.read(File.join(@path, "New-Page-2.textile"))
    assert !File.exist?(File.join(@path, "New-Page.md"))
  end

  test "delete a page" do
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    page = @wiki.page("New Page")
    @wiki.delete_page(page, commit_details)
    assert !File.exist?(File.join(@path, "New-Page.md"))
  end

  teardown do
    FileUtils.rm_r(@path)
  end
end

context "page_file_dir option" do
  setup do
    @path = cloned_testpath('examples/page_file_dir')
    @repo = Grit::Repo.init(@path)
    @page_file_dir = 'docs'
    @wiki = Stinker::Site.new(@path, :page_file_dir => @page_file_dir)
  end

  test "write a page in sub directory" do
    assert_equal @page_file_dir, @wiki.page_file_dir
    @wiki.write_page("New Page", :markdown, "Hi", commit_details)
    assert_equal "Hi", File.read(File.join(@path, @page_file_dir, "New-Page.md"))
    assert !File.exist?(File.join(@path, "New-Page.md"))
  end

  test "write a page in nested sub directory" do
    @wiki.write_page("Foo/TestNestPage", :markdown, "Hi", commit_details)
    assert !File.exist?(File.join(@path, "TestNestPage.md"))
    assert !File.exist?(File.join(@path, 'foo', "TestNestPage.md"))
    assert_equal "Hi", File.read(File.join(@path, @page_file_dir, 'foo', "TestNestPage.md"))
  end

  test "update page with nesting change" do
    @wiki.write_page("Gollum", :markdown, "# Gollum", commit_details)
    page = @wiki.page("Gollum")
    assert_equal File.join(@page_file_dir, 'Gollum.md'), page.path
    assert_equal 'Gollum', page.name
    @wiki.update_page(page, 'Foobar/Gollum', :markdown, "h1. Gollum", commit_details)
    page = @wiki.page("Gollum")
    assert_equal 2, @wiki.pages.size
    assert_equal File.join(@page_file_dir, 'foobar', 'Gollum.md'), page.path
    @wiki.update_page(page, 'Smeagol', :markdown, "h1. Gollum", commit_details)
    page = @wiki.page("Smeagol")
    assert_equal 2, @wiki.pages.size
    assert_equal File.join(@page_file_dir, 'foobar', 'Smeagol.md'), page.path
    @wiki.update_page(page, '/Smeagol', :markdown, "h1. Gollum", commit_details)
    page = @wiki.page("Smeagol")
    assert_equal 2, @wiki.pages.size
    assert_equal File.join(@page_file_dir, 'Smeagol.md'), page.path
    
  end

  test "is able differentiate similar pages in nested dirs" do
    @wiki.write_page("quux", :markdown, "# Gollum", commit_details)
    @wiki.write_page("nest1/quux", :markdown, "# Gollum", commit_details)
    @wiki.write_page("nest2/quux", :markdown, "# Gollum", commit_details)

    page1 = @wiki.page('nest1/quux').path
    page2 = @wiki.page('nest2/quux').path
    page3 = @wiki.page('quux').path
    assert_not_equal page1, page2
    assert_not_equal page2, page3
    assert_not_equal page1, page3

    
  end

  test "is able to give nested dir in name if duplicates" do
    @wiki.write_page("quux", :markdown, "# Gollum", commit_details)
    @wiki.write_page("nest1/quux", :markdown, "# Gollum", commit_details)
    @wiki.write_page("nest2/quux", :markdown, "# Gollum", commit_details)
    page1 = @wiki.page('nest1/quux').name
    page2 = @wiki.page('nest2/quux').name
    page3 = @wiki.page('quux').name
    assert_equal 'nest1/quux', page1
    assert_equal 'nest2/quux', page2
    assert_equal 'quux', page3

    
  end


  test "a file in page file dir should be found" do
    assert @wiki.page("foo")
  end

  test "a file out of page file dir should not be found" do
    assert !@wiki.page("bar")
  end

  test "search results should be restricted in page filer dir" do
    results = @wiki.search("foo")
    assert_equal 1, results.size
    assert_equal "foo", results[0][:name]
  end

  teardown do
    FileUtils.rm_r(@path)
  end
end

context "Wiki page writing with different branch" do
  setup do
    @path = testpath("examples/test.git")
    FileUtils.rm_rf(@path)
    @repo = Grit::Repo.init_bare(@path)
    @wiki = Stinker::Site.new(@path)

    # We need an initial commit to create the master branch
    # before we can create new branches
    cd = commit_details
    @wiki.write_page("Gollum", :markdown, "# Gollum", cd)

    # Create our test branch and check it out
    @repo.update_ref("test", @repo.commits.first.id)
    @branch = Stinker::Site.new(@path, :ref => "test")
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test "write_page" do
    cd = commit_details

    @branch.write_page("Bilbo", :markdown, "# Bilbo", commit_details)
    assert @branch.page("Bilbo")
    assert @wiki.page("Gollum")

    assert_equal 1, @wiki.repo.commits.size
    assert_equal 1, @branch.repo.commits.size

    assert_equal nil, @wiki.page("Bilbo")
  end
end
