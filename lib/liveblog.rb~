#!/usr/bin/env ruby

# file: liveblog.rb

require 'time'
require 'dynarex'
require 'fileutils'

class LiveBlog

  def initialize(liveblogfilepath='.')

    Dir.chdir liveblogfilepath
    @t = Time.now
    dxfile = File.join(path(), 'index.xml')
    @dx = Dynarex.new  dxfile if File.exists? dxfile
      
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
  
  def add_entry(hashtag, entry)
    
    a =  @dx.all
    rec = a.find {|section| section.x.lstrip.lines.first =~ /#\s*#{hashtag}/}
    
    if rec then
      rec.x += "\n" + entry
      save()      
      'section entry added'
    else
      'rec not found'
    end    
  end
  
  def add_section(entry)

    @dx.create({x: entry})
    save()
  end

  def save()
    
    @dx.save File.join(path(), 'index.xml')
    File.write File.join(path(), 'index.txt'), @dx.to_s
  end
  
  private
  
  def path

    File.join [@t.year.to_s, Date::MONTHNAMES[@t.month].downcase[0..2], \
                                                                @t.day.to_s]
  end

  def ordinalize(n)
    n.to_s + ( (10...20).include?(n) ? 'th' : 
              %w{ th st nd rd th th th th th th }[n % 10] )
  end  
  
end
