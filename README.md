stinker -- A site built on top of Git
====================================

## DESCRIPTION

Stinker is a simple site system built on top of Git. It's based on the
incredibly awesome Gollum project (Smeagol was already taken as a gem, and
Sam calls Gollum "Stinker" in the Two Towers). 

Stinker tries to combine ideas from Gollum and Jekyll to create static
sites that are Git powered and also have the awesome API and web
interface Gollum has.

Stinker sites can be edited:

* With your favorite text editor or IDE.
* With the built-in web interface.
* With the Ruby API.

By default, Stinker sites will be nanoc based, but should work well with
Jekyll as well, since it has the same support for file metadata.

(The only real difference between them for purposes of file access that
stinker provides is where they place the files.)


## MODIFICATIONS TO GOLLUM

A list of modifications made from the standard Gollum that this is
forked from:

* Saving of metadata in page files with yaml - same way Jekyll and Nanoc
  use it
* Support for content types setting (content types will show meta data
  fields in editor)
* Loads some config variables from a config.yml (base_path,
  page_file_dir)
* Better support for subdirectories. There's not a global pagename
  space any more, and creating a page named "foo/bar" will actually save
  in the directory foo.
* Sanitization turned off by default. It's assumed that contributers are trusted
  enough to allow snippets of HTML. 
* Extra wiki-ish formatting turned off (so feature set matches up better
  with Jekyll/Nanoc - might be worth bringing [[page]] style links into
  those projects and turning back on)

  
## INSTALLATION

The best way to install Stinker is with RubyGems:

    $ [sudo] gem install stinker

If you're installing from source, you can use [Bundler][bundler] to pick up all the
gems:

    $ bundle install # ([more info](http://gembundler.com/bundle_install.html))

In order to use the various formats that Gollum supports, you will need to
separately install the necessary dependencies for each format. You only need
to install the dependencies for the formats that you plan to use.

* [ASCIIDoc](http://www.methods.co.nz/asciidoc/) -- `brew install asciidoc`
* [Creole](http://wikicreole.org/) -- `gem install creole`
* [Markdown](http://daringfireball.net/projects/markdown/) -- `gem install rdiscount`
* [Org](http://orgmode.org/) -- `gem install org-ruby`
* [Pod](http://search.cpan.org/dist/perl/pod/perlpod.pod) -- `Pod::Simple::HTML` comes with Perl >= 5.10. Lower versions should install Pod::Simple from CPAN.
* [RDoc](http://rdoc.sourceforge.net/)
* [ReStructuredText](http://docutils.sourceforge.net/rst.html) -- `easy_install docutils`
* [Textile](http://www.textism.com/tools/textile/) -- `gem install RedCloth`
* [MediaWiki](http://www.mediawiki.org/wiki/Help:Formatting) -- `gem install wikicloth`

[bundler]: http://gembundler.com/

## RUNNING

Viewing/editing is not yet supported.


## REPO STRUCTURE

A Stinker repository's contents are designed to be nanoc-compatible.


## PAGE FILES

Page files may be written in any format supported by
[GitHub-Markup](http://github.com/github/markup) (except roff). The
current list of formats and allowed extensions is:

* ASCIIDoc: .asciidoc
* Creole: .creole
* Markdown: .markdown, .mdown, .mkdn, .mkd, .md
* Org Mode: .org
* Pod: .pod
* RDoc: .rdoc
* ReStructuredText: .rest.txt, .rst.txt, .rest, .rst
* Textile: .textile
* MediaWiki: .mediawiki, .wiki

Stinker detects the page file format via the extension, so files must have one
of the supported extensions in order to be converted.

Stinker does not have the filename restrictions that Gollum has. 

## LAYOUTS

Stinker will not support editing layouts from the web interface, but 
they can be accessed and edited in the layouts directory. The stinker
interface will allow choosing a 


## HTML SANITIZATION

This feature isn't supported currently. It's been turned off.

## GOLLUM FORMATTING

Gollum formatting has been removed, as it applies more to wikis.

## API DOCUMENTATION

The Stinker API allows you to retrieve raw or formatted  content from a Git
repository, write new content to the repository, and collect various meta data
about the site as a whole.

Initialize the Stinker::Repo object:

    # Require rubygems if necessary
    require 'rubygems'

    # Require the Gollum library
    require 'stinker'

    # Create a new Gollum::Wiki object by initializing it with the path to the
    # Git repository.
    site = Stinker::Site.new("my-site-repo.git")
    # => <Stinker::Site>

Get the latest version of the given human or canonical page name:

    page = site.page('page-name')
    # => <Stinker::Page>

    page.raw_data
    # => "# My wiki page"

    page.formatted_data
    # => "<h1>My wiki page</h1>"

    page.format
    # => :markdown

    vsn = page.version
    # => <Grit::Commit>

    vsn.id
    # => '3ca43e12377ea1e32ea5c9ce5992ec8bf266e3e5'

Get a list of versions for a given page:

    vsns = site.page('page-name').versions
    # => [<Grit::Commit, <Grit::Commit, <Grit::Commit>]

    vsns.first.id
    # => '3ca43e12377ea1e32ea5c9ce5992ec8bf266e3e5'

    vsns.first.authored_date
    # => Sun Mar 28 19:11:21 -0700 2010

Get a specific version of a given canonical page file:

    site.page('page-name', '5ec521178e0eec4dc39741a8978a2ba6616d0f0a')

Get the latest version of a given static file:

    file = site.file('asset.js')
    # => <Gollum::File>

    file.raw_data
    # => "alert('hello');"

    file.version
    # => <Grit::Commit>

Get a specific version of a given static file:

    site.file('asset.js', '5ec521178e0eec4dc39741a8978a2ba6616d0f0a')

Get an in-memory Page preview (useful for generating previews for web
interfaces):

    preview = site.preview_page("My Page", "# Contents", :markdown)
    preview.formatted_data
    # => "<h1>Contents</h1>"

Methods that write to the repository require a Hash of commit data that takes
the following form:

    commit = { :message => 'commit message',
               :name => 'Tom Preston-Werner',
               :email => 'tom@github.com' }

Write a new version of a page (the file will be created if it does not already
exist) and commit the change. The file will be written at the root or
a specified path.

    site.write_page('Page Name', :markdown, 'Page contents', commit)

Update an existing page. If the format is different than the page's current
format, the file name will be changed to reflect the new format.

    page = site.page('Page Name')
    site.update_page(page, page.name, page.format, 'Page contents', commit)

To delete a page and commit the change:

    site.delete_page(page, commit)


