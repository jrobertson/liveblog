#!/usr/bin/env ruby

# file: liveblog.rb

require 'time'
require 'dynarex'
require 'fileutils'
require 'martile'

class LiveBlog

  def initialize(liveblogfilepath='.', urlbase: '/liveblog')

    Dir.chdir liveblogfilepath
    
    @urlbase = urlbase
    @t = Time.now
    dxfile = File.join(path(), 'index.xml')

    File.exists?(dxfile) ? @dx = Dynarex.new(dxfile) : new_file()      
      
  end

  def new_file

s =<<EOF    
<?dynarex schema="sections[title]/section(x)"?>
title: LiveBlog #{ordinalize(@t.day) + @t.strftime(" %B %Y")} 
--#

EOF

    FileUtils.mkdir_p path()

    @dx = Dynarex.new 
    @dx.import s
    @dx.default_key = 'uid'
    
    save()
    
  end
  
  def add_entry(hashtag, raw_entry)
    
    entry = String.new(raw_entry)
    a =  @dx.all
    rec = a.find {|section| section.x.lstrip.lines.first =~ /#\s*#{hashtag}/}
    
    if rec then
      
      hashtag = entry.slice!(/#\w+$/)      
      rec.x += "\n" + entry.rstrip
      save()      

      [true, "%s %s/%s/index.html%s" % [entry, @urlbase, path(), hashtag]]
    else
      [false, 'rec not found']
    end    
  end
  
  def add_section(entry)

    hashtag = entry[/#\w+$/]
    @dx.create({x: entry})
    save()
    
    [true, "%s %s/%s/index.html%s" % [entry, @urlbase, path(), hashtag]]
  end

  def save()
    
    @dx.save File.join(path(), 'index.xml')
    File.write File.join(path(), 'index.txt'), @dx.to_s
    save_html()
  end
  
  private
  
  def path

    File.join [@t.year.to_s, Date::MONTHNAMES[@t.month].downcase[0..2], \
                                                                @t.day.to_s]
  end
  
  def save_html()
    
    newfilepath = File.join(path(), 'formatted.xml')
    FileUtils.cp File.join(path(), 'index.xml'), newfilepath
    
    doc = Rexle.new File.read(newfilepath)
    
    doc.root.xpath('records/section/x') do |x|
       html = RDiscount.new(Martile.new(x.text).to_html).to_html
       e = x.parent
       x.delete
       e.add Rexle.new("<x>%s</x>" % html).root
    end

    File.write newfilepath, doc.xml(pretty: true)
    
  end

  def ordinalize(n)
    n.to_s + ( (10...20).include?(n) ? 'th' : 
              %w{ th st nd rd th th th th th th }[n % 10] )
  end  
  
end