#!/usr/bin/env ruby

# file: liveblog.rb

require 'time'
require 'dynarex'
require 'fileutils'
require 'martile'
require 'simple-config'

class LiveBlog

  def initialize(config: nil)


    config ||= 'liveblog.conf' 
    h = SimpleConfig.new(config).to_h
    dir, @urlbase, @edit_url, @css_url, @xsl_path, @xsl_url, @bannertext = \
     %i(dir urlbase edit_url css_url xsl_path xsl_url bannertext).map{|x| h[x]}

    
    Dir.chdir dir    

    @d = Date.today
    dxfile = File.join(path(), 'index.xml')

    if File.exists? dxfile then 
    
      @dx = Dynarex.new(dxfile)
      @d = Date.parse @dx.title
      
    else
      
      new_file()
      link_today()
      
    end
      
  end
  
  def add_entry(raw_entry)

    entry, hashtag = raw_entry.split(/\s*(?=#\w+$)/)
    hashtag.downcase!
    
    success, msg = case raw_entry
    
    when /^#\s*\w.*#\w+$/ then
      
      add_section raw_entry
      
    when /#\w+$/ then 
      
      entry.gsub!(/(?:^|\s)!t\b/, time())
      add_section_entry entry, hashtag      
      
    else 
      [false, 'no valid entry found']
    end
    
    return [false, msg] unless success
    
    save()
    
    # we reserve 30 characters for the link
    len = (140 - 30 - hashtag.length)
    raw_entry.gsub!(/(?:^|\s)!t\b/,'')
    entry = raw_entry.length > len ? "%s... %s" % [raw_entry.slice(0, len), hashtag] : raw_entry
    message = "%s %s%s" % [entry, static_urlpath(), hashtag]
    
    [true, message]
  end
  
  # Use with yesterday's liveblog; 
  #
  def link_today()
    
    newfilepath = File.join(path(@d-1), 'formatted.xml')

    return unless File.exists? newfilepath

    doc = Rexle.new File.read(newfilepath)    
    doc.root.element('summary/next_day').text = static_urlpath()
    File.write newfilepath, doc.xml(pretty: true)
    
    render_html doc, @d-1
    
  end

  def new_file(s=nil)

s ||= <<EOF    
<?dynarex schema="sections[title]/section(x)" order='descending'?>
title: LiveBlog #{ordinalize(@d.day) + @d.strftime(" %B %Y")}
--#

EOF

    t = Time.now
    # keyword substitions
    # a !t becomes the Time.now.strftime("%-I:%M%P") #=> 4:27pm
    s.gsub!(/\B\*started\s+<time>(\d+:\d+[ap]m)<\/time>\*\B\s*!tc/) do |x|

      raw_start_time = $1

      start_time = Time.parse raw_start_time
      seconds = t - start_time
      list = Subunit.new(units={minutes:60, hours:60}, seconds: seconds )\
                                                                     .to_h.to_a
      n = list.find {|_,v| v > 0 }
      duration = list[list.index(n)..-2].map {|x|"%d %s" % x.reverse}\
                                                                    .join(', ')
      "*completed %s; duration: %s*" % [time(t), duration]
    end
    
    s.gsub!(/\B!ts\b/, "*started #{time(t)}*")
    s.gsub!(/\B!tc\b/, "*completed #{time(t)}*")
    s.gsub!(/(?:^|\s)!t\b/,  time(t))


    FileUtils.mkdir_p File.join(path())

    @dx = Dynarex.new 
    @dx.import s
    @dx.default_key = 'uid'
    
    save()
    
  end
  
  alias import new_file  
  
  private

  
  def add_section_entry(raw_entry, hashtag)
    
    rec = @dx.all.find {|section| section.x.lstrip.lines.first =~ /#{hashtag}/i}
    
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

    add summary, 'edit_url', "%s/%s" % [@edit_url, urlpath()]
    add summary, 'date',      @d.strftime("%d-%b-%Y").upcase
    add summary, 'day',   Date::DAYNAMES[@d.cwday]
    add summary, 'css_url',   @css_url
    add summary, 'published', Time.now.strftime("%d-%m-%Y %H:%M")
    add summary, 'prev_day',  static_urlpath(@d-1)
    add summary, 'next_day', @d == Date.today ? '' : static_urlpath(@d+1)
    add summary, 'bannertext',   @bannertext    
  
    tags = Rexle::Element.new('tags')
    
    doc.root.xpath('records/section/x/text()').each do |x| 
      tags.add Rexle::Element.new('tag').add_text x.lines.first[/#(\w+)$/,1]\
                                                                      .downcase
    end
    
    summary.add tags
    
    domain = @urlbase[/https?:\/\/([^\/]+)/,1].split('.')[-2..-1].join('.')

    doc.root.xpath('records/section/x') do |x|

      s = "=%s\n%s\n=" % [x.text.lines.first[/#\w+$/], x.text.unescape]
      html = Martile.new(s, ignore_domainlabel: domain).to_html

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
    
    doc.instructions << [
      'xml-stylesheet',
      "title='XSL_formatting' type='text/xsl' href='#{@xsl_url}'"
    ]
    
    File.write newfilepath, doc.xml(pretty: true)
    
    render_html doc
    
    # save the related CSS file locally if the file doesn't already exist
    if not File.exists? 'liveblog.css' then
      FileUtils.cp File.join(File.dirname(__FILE__), 'liveblog.css'),\
                                                                 'liveblog.css'
    end
    
  end

  def ordinalize(n)
    n.to_s + ( (10...20).include?(n) ? 'th' : 
              %w{ th st nd rd th th th th th th }[n % 10] )
  end  

  def add(summary, name, s)
    summary.add Rexle::Element.new(name).add_text s
  end

  def render_html(doc, d=@d)

    xslt_buffer = if @xsl_path then
      buffer, _ = RXFHelper.read @xsl_path
      buffer
    else
      lib = File.exists?('liveblog.xsl') ? '.' : File.dirname(__FILE__)
      File.read(File.join(lib,'liveblog.xsl'))
    end

    xslt  = Nokogiri::XSLT(xslt_buffer)
    out = xslt.transform(Nokogiri::XML(doc.xml))
    File.write File.join(path(d), 'index.html'), out    
  end
  
  def time(t=Time.now)
    t.strftime "<time>%-I:%M%P</time>"
  end
  
end