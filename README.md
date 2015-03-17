# Introducing the LiveBlog gem

## Creating the config file

    require 'liveblog'

    tmp = '/tmp/liveblog'
    FileUtils.mkdir_p tmp
    Dir.chdir tmp

    config =<<EOF
    dir: #{tmp}
    urlbase: http://www.someurl.com/liveblog/
    edit_url: http://www.someurl.com/edit/liveblog
    css_url: /liveblog/liveblog.css
    EOF

    File.write 'liveblog.conf', config

## Adding a new heading

    lb = LiveBlog.new
    s = '# Testing a New Heading #liveblog'
    success, msg = lb.add_entry s

    #=> [true, "# Testing a New Heading #liveblog http://www.someurl.com/liveblog/2015/mar/17/#liveblog"] 


## Adding an entry for #liveblog

    lb = LiveBlog.new
    s = 'This is just a regular paragraph. #liveblog'
    success, msg = lb.add_entry s
    #=> [true, "This is just a regular paragraph. #liveblog http://www.someurl.com/liveblog/2015/mar/17/#liveblog"] 

## Importing a raw document into LiveBlog

    s =<<EOF 
    <?dynarex schema="sections[title]/section(x)" format_mask="[!x]"?>
    title: LiveBlog 17th March 2015
    --#

    # Testing a New Heading #liveblog

    This is just a regular paragraph.

    # Things to do this week #gtd    
    Car maintenance:

    * Check oil level and top-up if necessary
    * Pump up the tyres
    EOF

    lb = LiveBlog.new
    lb.import s

## Observations

Within the liveblog sub-directory for the day, there should be several files created, including:

* index.xml
* index.txt
* formatted.xml
* index.html

Within the liveblog parent directory the following files should have been created:

* liveblog.conf
* liveblog.xsl
* liveblog.css

## Resources

* [liveblog](https://rubygems.org/gems/liveblog)

liveblog gem
