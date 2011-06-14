# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

context "Site" do
  setup do
    @wiki = Stinker::Site.new(testpath("examples/lotr.git"))
  end

  test "normalizes commit hash" do
    commit = {:message => 'abc'}
    name  = @wiki.repo.config['user.name']
    email = @wiki.repo.config['user.email']
    committer = Stinker::Committer.new(@wiki, commit)
    assert_equal name,  committer.actor.name
    assert_equal email, committer.actor.email

    commit[:name]  = 'bob'
    commit[:email] = ''
    committer = Stinker::Committer.new(@wiki, commit)
    assert_equal 'bob',  committer.actor.name
    assert_equal email, committer.actor.email

    commit[:email] = 'foo@bar.com'
    committer = Stinker::Committer.new(@wiki, commit)
    assert_equal 'bob',  committer.actor.name
    assert_equal 'foo@bar.com', committer.actor.email
  end

  test "yield after_commit callback" do
    @path = cloned_testpath('examples/lotr.git')
    yielded = nil
    begin
      wiki = Stinker::Site.new(@path)
      committer = Stinker::Committer.new(wiki)
      committer.after_commit do |index, sha1|
        yielded = sha1
        assert_equal committer, index
      end

      res = wiki.write_page("Stinker", :markdown, "# Stinker", 
        :committer => committer)

      assert_equal committer, res

      sha1 = committer.commit
      assert_equal sha1, yielded
    ensure
      FileUtils.rm_rf(@path)
    end
  end

  test "parents with default master ref" do
    ref = 'a8ad3c09dd842a3517085bfadd37718856dee813'
    committer = Stinker::Committer.new(@wiki)
    assert_equal ref,  committer.parents.first.sha
  end

  test "parents with custom ref" do
    ref = '60f12f4254f58801b9ee7db7bca5fa8aeefaa56b'
    @wiki = Stinker::Site.new(testpath("examples/lotr.git"), :ref => ref)
    committer = Stinker::Committer.new(@wiki)
    assert_equal ref,  committer.parents.first.sha
  end
end
