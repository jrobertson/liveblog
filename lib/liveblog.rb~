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
    [true, "%s %s/%s/%s" % [entry, @urlbase, path(), hashtag]]
  end    

  
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
  
  def path

    File.join [@t.year.to_s, Date::MONTHNAMES[@t.month].downcase[0..2], \
                                                                @t.day.to_s]
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
    
    doc.root.xpath('records/section/x') do |x|

      s = "=%s\n%s\n=" % [x.text.lines.first[/#\w+$/], x.text]
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
    
  end

  def ordinalize(n)
    n.to_s + ( (10...20).include?(n) ? 'th' : 
              %w{ th st nd rd th th th th th th }[n % 10] )
  end  
  
end