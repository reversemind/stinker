# ~*~ encoding: utf-8 ~*~
path = File.join(File.dirname(__FILE__), "helper") 
require File.expand_path(path)

context "File" do
  setup do
    @wiki = Stinker::Site.new(testpath("examples/lotr.git"), :asset_extensions => %w(csv jpg))
    @path = cloned_testpath("examples/lotr")
    @mordor = Stinker::Site.new(@path, :asset_file_dir => 'Mordor')
  end

  test "new file" do
    file = Stinker::File.new(@wiki)
    assert_nil file.raw_data
  end

  test "existing file" do
    commit = @wiki.repo.commits.first
    file   = @wiki.file("Mordor/todo.txt")
    assert_equal "[ ] Write section on Ents\n", file.raw_data
    assert_equal 'todo.txt',         file.name
    assert_equal commit.id,          file.version.id
    assert_equal commit.author.name, file.version.author.name
  end

  test "accessing tree" do
    assert_nil @wiki.file("Mordor")
  end

  test "file list" do
    assert_equal ["Data.csv", "Mordor/eye.jpg", "Mordor/todo.txt"], @wiki.files.map(&:path)
    assert_equal ["Mordor/eye.jpg", "Mordor/todo.txt"], @mordor.files.map(&:path)
  end

  test "asset list" do
    assert @wiki.assets.first.asset?

    assert_equal ["Data.csv", "Mordor/eye.jpg"], @wiki.assets.map(&:path)
    assert_equal ["Mordor/eye.jpg"], @mordor.assets.map(&:path)
  end

  test "can delete" do
    @file = @mordor.files.first
    assert File.exist?(File.join(@path, @file.path))
    @mordor.delete_file(@file, {:name => 'Test', :email => 'test', :message => 'deleting'})

    assert_equal 1, @mordor.files.size
    assert !File.exist?(File.join(@path, @file.path))
  end

  test "can add" do
    assert_equal 2, @mordor.files.size
    @file = @mordor.file('Mordor/eye.jpg')
    @mordor.write_file('newfile.jpg', @file.raw_data, {:name => 'Test', :email => 'test', :message => 'adding'})
    @new_file =  @mordor.file('Mordor/newfile.jpg')
    assert_not_equal nil, @new_file
    assert File.exist?(File.join(@path, @new_file.path))
    assert_equal 3,@mordor.files.size
    assert_equal @file.raw_data, @new_file.raw_data
  end


  teardown do
    FileUtils.rm_r(@path)
  end

end
