Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '0.0.2'

  s.name              = 'stinker'
  s.version           = '0.0.3'
  s.date              = '2011-07-11'
  s.rubyforge_project = 'stinker'

  s.summary     = "A simple, Git-powered site."
  s.description = "A simple, Git-powered site with a sweet API and local frontend based on gollum."

  s.authors  = ["Tom Preston-Werner", "Rick Olson", "David Haslem"]
  s.email    = 'therabidbanana@gmail.com'
  s.homepage = 'http://github.com/therabidbanana/stinker'

  s.require_paths = %w[lib]

  s.executables = ["stinker"]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md LICENSE]

  s.add_dependency('grit', "~> 2.4.1")
  s.add_dependency('github-markup', [">= 0.4.0", "< 1.0.0"])
  s.add_dependency('albino', "~> 1.3.2")
  s.add_dependency('sinatra', "~> 1.0")
  s.add_dependency('mustache', [">= 0.11.2", "< 1.0.0"])
  s.add_dependency('sanitize', "~> 2.0.0")
  s.add_dependency('nokogiri', "~> 1.4")

  s.add_development_dependency('RedCloth')
  s.add_development_dependency('mocha')
  s.add_development_dependency('org-ruby')
  s.add_development_dependency('rdiscount')
  s.add_development_dependency('shoulda')
  s.add_development_dependency('rack-test')
  s.add_development_dependency('wikicloth')

  # = MANIFEST =
  s.files = %w[
    Gemfile
    HISTORY.md
    Home.md
    LICENSE
    README.md
    Rakefile
    bin/stinker
    docs/sanitization.md
    lib/stinker.rb
    lib/stinker/albino.rb
    lib/stinker/blob_entry.rb
    lib/stinker/committer.rb
    lib/stinker/file.rb
    lib/stinker/frontend/app.rb
    lib/stinker/frontend/public/css/dialog.css
    lib/stinker/frontend/public/css/editor.css
    lib/stinker/frontend/public/css/gollum.css
    lib/stinker/frontend/public/css/ie7.css
    lib/stinker/frontend/public/css/template.css
    lib/stinker/frontend/public/images/icon-sprite.png
    lib/stinker/frontend/public/javascript/editor/gollum.editor.js
    lib/stinker/frontend/public/javascript/editor/langs/asciidoc.js
    lib/stinker/frontend/public/javascript/editor/langs/creole.js
    lib/stinker/frontend/public/javascript/editor/langs/markdown.js
    lib/stinker/frontend/public/javascript/editor/langs/org.js
    lib/stinker/frontend/public/javascript/editor/langs/pod.js
    lib/stinker/frontend/public/javascript/editor/langs/rdoc.js
    lib/stinker/frontend/public/javascript/editor/langs/textile.js
    lib/stinker/frontend/public/javascript/gollum.dialog.js
    lib/stinker/frontend/public/javascript/gollum.js
    lib/stinker/frontend/public/javascript/gollum.placeholder.js
    lib/stinker/frontend/public/javascript/jquery.color.js
    lib/stinker/frontend/public/javascript/jquery.js
    lib/stinker/frontend/templates/compare.mustache
    lib/stinker/frontend/templates/create.mustache
    lib/stinker/frontend/templates/edit.mustache
    lib/stinker/frontend/templates/editor.mustache
    lib/stinker/frontend/templates/error.mustache
    lib/stinker/frontend/templates/history.mustache
    lib/stinker/frontend/templates/layout.mustache
    lib/stinker/frontend/templates/page.mustache
    lib/stinker/frontend/templates/pages.mustache
    lib/stinker/frontend/templates/search.mustache
    lib/stinker/frontend/templates/searchbar.mustache
    lib/stinker/frontend/views/compare.rb
    lib/stinker/frontend/views/create.rb
    lib/stinker/frontend/views/edit.rb
    lib/stinker/frontend/views/editable.rb
    lib/stinker/frontend/views/error.rb
    lib/stinker/frontend/views/history.rb
    lib/stinker/frontend/views/layout.rb
    lib/stinker/frontend/views/page.rb
    lib/stinker/frontend/views/pages.rb
    lib/stinker/frontend/views/search.rb
    lib/stinker/git_access.rb
    lib/stinker/markup.rb
    lib/stinker/page.rb
    lib/stinker/pagination.rb
    lib/stinker/sanitization.rb
    lib/stinker/site.rb
    stinker.gemspec
    templates/formatting.html
    test/examples/config.git/HEAD
    test/examples/config.git/config
    test/examples/config.git/description
    test/examples/config.git/hooks/applypatch-msg.sample
    test/examples/config.git/hooks/commit-msg.sample
    test/examples/config.git/hooks/post-commit.sample
    test/examples/config.git/hooks/post-receive.sample
    test/examples/config.git/hooks/post-update.sample
    test/examples/config.git/hooks/pre-applypatch.sample
    test/examples/config.git/hooks/pre-commit.sample
    test/examples/config.git/hooks/pre-rebase.sample
    test/examples/config.git/hooks/prepare-commit-msg.sample
    test/examples/config.git/hooks/update.sample
    test/examples/config.git/info/exclude
    test/examples/config.git/objects/0f/c230583b53ca0cf39416e365992bc6a27b5d69
    test/examples/config.git/objects/10/1aab8ca3d64162622d8799a046805a650e67ad
    test/examples/config.git/objects/25/a2e673523692991f2a927848c293f3fe00ccbb
    test/examples/config.git/objects/3e/829eefa4f13261514b16a5b172849c389a1fa2
    test/examples/config.git/objects/56/19752e68b09cd35946bff9aa244f273ddef499
    test/examples/config.git/objects/76/4b7e6759ae5332b59a3fde3e6be00529239dd7
    test/examples/config.git/objects/a0/fd6b37769baa100a98417b63b6739ad972d573
    test/examples/config.git/objects/c8/df4f2ab85d5601a62abed312b5e0755f4c62d1
    test/examples/config.git/objects/cd/7b043a2e86325df49161af254fb0f1878b99c7
    test/examples/config.git/objects/f0/96c52ee299c85c31e94bef7cc9822a4c8a1ebd
    test/examples/config.git/objects/pack/pack-3aa9fe0c29dbb1588f801c8037d04eaa07bfc880.idx
    test/examples/config.git/objects/pack/pack-3aa9fe0c29dbb1588f801c8037d04eaa07bfc880.pack
    test/examples/config.git/packed-refs
    test/examples/lotr.git/HEAD
    test/examples/lotr.git/config
    test/examples/lotr.git/description
    test/examples/lotr.git/hooks/applypatch-msg.sample
    test/examples/lotr.git/hooks/commit-msg.sample
    test/examples/lotr.git/hooks/post-commit.sample
    test/examples/lotr.git/hooks/post-receive.sample
    test/examples/lotr.git/hooks/post-update.sample
    test/examples/lotr.git/hooks/pre-applypatch.sample
    test/examples/lotr.git/hooks/pre-commit.sample
    test/examples/lotr.git/hooks/pre-rebase.sample
    test/examples/lotr.git/hooks/prepare-commit-msg.sample
    test/examples/lotr.git/hooks/update.sample
    test/examples/lotr.git/info/exclude
    test/examples/lotr.git/objects/06/131480411710c92a82fe2d1e76932c70feb2e5
    test/examples/lotr.git/objects/0a/de1e2916346d4c1f2fb63b863fd3c16808fe44
    test/examples/lotr.git/objects/0e/d8cbe0a25235bd867e65193c7d837c66b328ef
    test/examples/lotr.git/objects/24/49c2681badfd3c189e8ed658dacffe8ba48fe5
    test/examples/lotr.git/objects/2c/b9156ad383914561a8502fc70f5a1d887e48ad
    test/examples/lotr.git/objects/5d/cac289a8603188d2c5caf481dcba2985126aaa
    test/examples/lotr.git/objects/60/f12f4254f58801b9ee7db7bca5fa8aeefaa56b
    test/examples/lotr.git/objects/67/44543452f832d4b193cdc06ca4dd3911acca3a
    test/examples/lotr.git/objects/71/4323c104239440a5c66ab12a67ed07a83c404f
    test/examples/lotr.git/objects/71/defbf428d09a095e51c44d6fb9a0bd4079abe9
    test/examples/lotr.git/objects/84/0ec5b1ba1320e8ec443f28f99566f615d5af10
    test/examples/lotr.git/objects/93/6b83ee0dd8837adb82511e40d5e4ebe59bb675
    test/examples/lotr.git/objects/94/523d7ae48aeba575099dd12926420d8fd0425d
    test/examples/lotr.git/objects/96/97dc65e095658bbd1b8e8678e08881e86d32f1
    test/examples/lotr.git/objects/a3/1ca2a7c352c92531a8b99815d15843b259e814
    test/examples/lotr.git/objects/a5/5de8e2fd3d1bb55eb0de36e5a610357dc28920
    test/examples/lotr.git/objects/a8/ad3c09dd842a3517085bfadd37718856dee813
    test/examples/lotr.git/objects/aa/b61fe89d56f8614c0a8151da34f939dcedfa68
    test/examples/lotr.git/objects/af/ab33931eee7d16d6890fefb1bd6f67650e8b1f
    test/examples/lotr.git/objects/b3/9a4b4015445e8588011d9951ae2e20e827c0f2
    test/examples/lotr.git/objects/c3/b43e9f08966b088e7a0192e436b7a884542e05
    test/examples/lotr.git/objects/dc/596d6b2dd89ab05c66f4abd7d5eb706bc17f19
    test/examples/lotr.git/objects/e5/30a4733b4c9ea561b769ad6832a1399e3994ea
    test/examples/lotr.git/objects/ec/da3205bee14520aab5a7bb307392064b938e83
    test/examples/lotr.git/objects/fa/e7ef5344202bba4129abdc13060d9297d99465
    test/examples/lotr.git/objects/info/packs
    test/examples/lotr.git/objects/pack/pack-dcbeaf3f6ff6c5eb08ea2b0a2d83626e8763546b.idx
    test/examples/lotr.git/objects/pack/pack-dcbeaf3f6ff6c5eb08ea2b0a2d83626e8763546b.pack
    test/examples/lotr.git/packed-refs
    test/examples/lotr.git/refs/heads/master
    test/examples/page_file_dir.git/COMMIT_EDITMSG
    test/examples/page_file_dir.git/HEAD
    test/examples/page_file_dir.git/config
    test/examples/page_file_dir.git/description
    test/examples/page_file_dir.git/index
    test/examples/page_file_dir.git/info/exclude
    test/examples/page_file_dir.git/logs/HEAD
    test/examples/page_file_dir.git/logs/refs/heads/master
    test/examples/page_file_dir.git/objects/0c/7d27db1f575263efdcab3dc650f4502a2dbcbf
    test/examples/page_file_dir.git/objects/22/b404803c966dd92865614d86ff22ca12e50c1e
    test/examples/page_file_dir.git/objects/25/7cc5642cb1a054f08cc83f2d943e56fd3ebe99
    test/examples/page_file_dir.git/objects/57/16ca5987cbf97d6bb54920bea6adde242d87e6
    test/examples/page_file_dir.git/objects/5b/43e14e0a15fb6f08feab1773d1c0991e9f71e2
    test/examples/page_file_dir.git/refs/heads/master
    test/examples/revert.git/COMMIT_EDITMSG
    test/examples/revert.git/HEAD
    test/examples/revert.git/config
    test/examples/revert.git/description
    test/examples/revert.git/index
    test/examples/revert.git/info/exclude
    test/examples/revert.git/logs/HEAD
    test/examples/revert.git/logs/refs/heads/master
    test/examples/revert.git/objects/20/2ced67cea93c7b6bd2928aa1daef8d1d55a20d
    test/examples/revert.git/objects/41/76394bfa11222363c66ce7e84b5f154095b6d9
    test/examples/revert.git/objects/6a/69f92020f5df77af6e8813ff1232493383b708
    test/examples/revert.git/objects/b4/785957bc986dc39c629de9fac9df46972c00fc
    test/examples/revert.git/objects/f4/03b791119f8232b7cb0ba455c624ac6435f433
    test/examples/revert.git/objects/info/packs
    test/examples/revert.git/objects/pack/pack-a561f8437234f74d0bacb9e0eebe52d207f5770d.idx
    test/examples/revert.git/objects/pack/pack-a561f8437234f74d0bacb9e0eebe52d207f5770d.pack
    test/examples/revert.git/packed-refs
    test/examples/revert.git/refs/heads/master
    test/examples/revert.git/refs/remotes/origin/HEAD
    test/examples/yubiwa.git/HEAD
    test/examples/yubiwa.git/config
    test/examples/yubiwa.git/description
    test/examples/yubiwa.git/info/exclude
    test/examples/yubiwa.git/objects/10/fa2ddc4e3b4009d8a453aace10bd6148c1ad00
    test/examples/yubiwa.git/objects/52/4b82874327ea7cbf730389964ba7cb3de966de
    test/examples/yubiwa.git/objects/58/3fc201cb457fb3f1480f3e1e5999b119633835
    test/examples/yubiwa.git/objects/87/bc1dd46ab3d3874d4e898d45dd512cc20a7cc8
    test/examples/yubiwa.git/objects/89/64ed1b4e21aa90e831763bbce9034bfda81b70
    test/examples/yubiwa.git/objects/9f/f6dd0660da5fba2d3374adb2b84fa653bb538b
    test/examples/yubiwa.git/objects/ac/e97abf2b177815a1972d7db22f229f58c83309
    test/examples/yubiwa.git/objects/b1/f443863a4816628807fbf86141ebef055dda34
    test/examples/yubiwa.git/refs/heads/master
    test/helper.rb
    test/test_app.rb
    test/test_committer.rb
    test/test_file.rb
    test/test_git_access.rb
    test/test_markup.rb
    test/test_page.rb
    test/test_page_revert.rb
    test/test_site.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
