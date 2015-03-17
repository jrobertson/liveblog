#!/usr/bin/env ruby

# file: liveblog.rb

require 'time'
require 'dynarex'
require 'fileutils'
require 'martile'

class LiveBlog

  def initialize(config: nil)


    config ||= 'liveblog.conf' 
    h = SimpleConfig.new(config).to_h
    dir, @urlbase, @edit_url, @css_url = %i(dir urlbase edit_url css_url).map{|x| h[x]}

    
    Dir.chdir dir    

    @d = Date.today
    dxfile = File.join(path(), 'index.xml')

    if File.exists? dxfile then 
    
      @dx = Dynarex.new(dxfile)
      @d = Date.parse @dx.title
      
    else
      
      new_file()
      
    end
      
  end
  
  def add_entry(raw_entry)

    entry, hashtag = raw_entry.split(/\s*(?=#\w+$)/)    
    
    success, msg = case raw_entry
    when /^#\s*\w.*#\w+$/ then add_section raw_entry
    when /#\w+$/ then add_section_entry entry, hashtag      
    else [false, 'no valid entry found']
    end
    
    return [false, msg] unless success
    
    save()
    
    # we reserve 30 characters for the link
    len = (140 - 30 - hashtag.length)
    entry = raw_entry.length > len ? "%s... %s" % [raw_entry.slice(0, len), hashtag] : raw_entry
    [true, "%s %s%s" % [entry, static_urlpath(), hashtag]]
  end
  
  # Use with yesterday's liveblog; Ideally suited for running from a cron job
  #
  def link_today()
    
    newfilepath = File.join(path(@d-1), 'formatted.xml')
    FileUtils.cp File.join(path(@d-1), 'index.xml'), newfilepath
    
    doc = Rexle.new File.read(newfilepath)    
    doc.root.element('summary/next_day').text = static_urlpath()
    File.write newfilepath, doc.xml(pretty: true)
    
  end

  def new_file(s=nil)

s ||= <<EOF    
<?dynarex schema="sections[title]/section(x)" order='descending'?>
title: LiveBlog #{ordinalize(@d.day) + @d.strftime(" %B %Y")}
--#

EOF

    FileUtils.mkdir_p File.join(path())

    @dx = Dynarex.new 
    @dx.import s
    @dx.default_key = 'uid'
    
    save()
    
  end
  
  alias import new_file  
  
  private

  
  def add_section_entry(raw_entry, hashtag)
    
    rec = @dx.all.find {|section| section.x.lstrip.lines.first =~ /#{hashtag}/}
    
    return [false, 'rec not found'] unless rec
          
    rec.x += "\n\n" + raw_entry.chomp + "\n"
    [true, 'entry added to section ' + hashtag]
  end
  
  def add_section(raw_entry)

    @dx.create({x: raw_entry})    
    [true, 'section added']
  end  
    
  
  def path(d=@d)
    [d.year.to_s, Date::MONTHNAMES[d.month].downcase[0..2], d.day.to_s]
  end
  
  def urlpath(d=@d)
    path(d).join('/') + '/'
  end
  
  def static_urlpath(d=@d)
    @urlbase.sub(/[^\/]$/,'\0/') + urlpath(d)
  end
  
    
  def save()
    
    @dx.save File.join(path(), 'index.xml')
    File.write File.join(path(), 'index.txt'), @dx.to_s
    save_html()
  end  
  
  def save_html()
    
    newfilepath = File.join(path(), 'formatted.xml')
    FileUtils.cp File.join(path(), 'index.xml'), newfilepath    
    doc = Rexle.new File.read(newfilepath)
    
    summary = doc.root.element('summary')

    add summary, 'edit_url', "%s/%sindex.txt" % [@edit_url, urlpath()]
    add summary, 'date',      @d.strftime("%d-%b-%Y").upcase
    add summary, 'css_url',   @css_url
    add summary, 'published', Time.now.strftime("%d-%m-%Y %H:%M")
    add summary, 'prev_day',  static_urlpath(@d-1)
    add summary, 'next_day', @d == Date.today ? '' : static_urlpath(@d+1)
  
    tags = Rexle::Element.new('tags')
    
    doc.root.xpath('records/section/x/text()').each do |x| 
      tags.add Rexle::Element.new('tag').add_text x.lines.first[/#(\w+)$/,1]
    end
    
    summary.add tags

    doc.root.xpath('records/section/x') do |x|

      s = "=%s\n%s\n=" % [x.text.lines.first[/#\w+$/], x.text.unescape]
      html = Martile.new(s).to_html

      e = x.parent
      x.delete
      doc2 = Rexle.new(html)
      
      h1 = doc2.root.element('h1')
      details = Rexle::Element.new('details')
      details.attributes[:open] = 'open'
      summary = Rexle::Element.new('summary')
      summary.add h1

      details.add summary
      doc2.root.xpath('.').each {|x| details.add x }     
      doc2.root.add details
      e.add doc2.root
    end

    File.write newfilepath, doc.xml(pretty: true)
    
    lib = File.exists?('liveblog.xsl') ? '.' : File.dirname(__FILE__)
    xslt_buffer = File.read(File.join(lib,'liveblog.xsl'))

    xslt  = Nokogiri::XSLT(xslt_buffer)
    out = xslt.transform(Nokogiri::XML(doc.xml))
    File.write File.join(path(), 'index.html'), out
    
    # save the related CSS file locally if the file doesn't already exist
    if not File.exists? 'liveblog.css' then
      FileUtils.cp File.join(File.dirname(__FILE__), 'liveblog.css'),\
                            'liveblog.css' if not File.exists? 'liveblog.css'
    end
    
  end

  def ordinalize(n)
    n.to_s + ( (10...20).include?(n) ? 'th' : 
              %w{ th st nd rd th th th th th th }[n % 10] )
  end  

  def add(summary, name, s)
    summary.add Rexle::Element.new(name).add_text s
  end
  
end