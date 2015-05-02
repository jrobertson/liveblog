#!/usr/bin/env ruby

# file: liveblog.rb

require 'time'
require 'dynarex'
require 'fileutils'
require 'martile'
require 'simple-config'
require 'rexle-diff'

class LiveBlog

  # the config can either be a hash, a config filepath, or nil
  #
  def initialize(x=nil, config: nil, date: Date.today)        
    
    config = if x or config then
    
      x || config
    else
      
      if File.exists? 'liveblog.conf' then 
        'liveblog.conf'
      else
        sc = SimpleConfig.new(new_config())
        File.write 'liveblog.conf', sc.write
        sc
      end
    end
    
    h = SimpleConfig.new(config).to_h

    dir, @urlbase, @edit_url, @css_url, @xsl_path, \
                       @xsl_url, @bannertext, @title, @rss_title, @rss_lang = \
     (%i(dir urlbase edit_url css_url xsl_path xsl_url bannertext)\
                                  + %i(title rss_title rss_lang)).map{|x| h[x]}

    @title ||= 'LiveBlog'
    @rss_lang ||= 'en-gb'
    
    Dir.chdir dir    

    @d = date
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

    entry, hashtag = raw_entry.split(/\s*#(?=\w+$)/)
    hashtag.downcase!
    
    success, msg = case raw_entry
    
    when /^#\s*\w.*#\w+$/ then
      
      add_section raw_entry, hashtag
      
    when /#\w+$/ then 
      
      entry.gsub!(/(?:^|\s)!t\s/, '\1' + time())
      add_section_entry entry, hashtag
      
    else 
      [false, 'no valid entry found']
    end
    
    return [false, msg] unless success
    
    save()
    
    # we reserve 30 characters for the link
    len = (140 - 30 - hashtag.length)
    raw_entry.gsub!(/(?:^|\s)!t\z/,'')
    entry = raw_entry.length > len ? "%s... %s" % [raw_entry.slice(0, len), hashtag] : raw_entry
    message = "%s %s#%s" % [entry, static_urlpath(), hashtag]
    
    [true, message]
  end
  
  # returns a RecordX object for a given hashtag
  #
  def find_hashtag(hashtag)    
    @dx.find hashtag[/\w+$/]
  end
  
  # Use with yesterday's liveblog; 
  #
  def link_today()
    
    raw_formatted_filepath = File.join(path(@d-1), 'formatted.xml')

    return unless File.exists? raw_formatted_filepath

    doc = Rexle.new File.read(raw_formatted_filepath)    
    doc.root.element('summary/next_day').text = static_urlpath()
    File.write raw_formatted_filepath, doc.xml(pretty: true)
    
    render_html doc, @d-1
    
  end

  def new_file(s=nil)

s ||= <<EOF    
<?dynarex schema="sections[title]/section(x)"?>
title: #{@title} #{ordinalize(@d.day) + @d.strftime(" %B %Y")}
--#

EOF

    t = Time.now
    # keyword substitions
    # a !t becomes the Time.now.strftime("%-I:%M%P") #=> 4:27pm
    s.gsub!(/\B\*started\s+<time>(\d+:\d+[ap]m)<\/time>\*\B\s*!tc\z/) do |x|

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
    
    s.gsub!(/(?:^|\s)ts\z/, "*started #{time(t)}*")
    s.gsub!(/(?:^|\s)!tc\z/, "*completed #{time(t)}*")
    s.gsub!(/(?:^|\s)!t\s/,  '\1' + time(t))


    FileUtils.mkdir_p File.join(path())

    @dx = Dynarex.new 
    @dx.import s
    
    @dx.xpath('records/section').each do |rec|
      
      rec.attributes[:uid] = rec.attributes[:id]
      rec.attributes[:id] = rec.text('x').lines.first[/#(\w+)$/,1]

    end
    
    @dx.instance_variable_set :@dirty_flag, true
    
    save()
    
  end
  
  alias import new_file  
  
  def save()

    @dx.save File.join(path(), 'index.xml')
    File.write File.join(path(), 'index.txt'), @dx.to_s
    save_html()
    save_rss()
    save_frontpage()
    FileUtils.cp File.join(path(),'raw_formatted.xml'), \
                                    File.join(path(),'raw_formatted.xml.bak')

  end      
  
  def update_entry(entry)
    
    hashtag = entry.lines.first[/#(\w+)$/,1]
                                
    record_found = find_hashtag hashtag
    
    if record_found then
      record_found.x = entry
      save()
      [true]
    else
      [false, 'record for #' + hashtag + ' not found.']
    end
    
  end
  
  
  private

  
  def add_section_entry(raw_entry, hashtag)
    
    rec = @dx.find hashtag
    
    return [false, 'rec not found'] unless rec
          
    rec.x += "\n\n" + raw_entry.chomp + "\n"
    [true, 'entry added to section ' + hashtag]
  end
  
  def add_section(raw_entry, hashtag)
    
    records = @dx.records
    uid = if records then
      r = records.max_by {|k,v| v[:uid].to_i}
      r ? r[1][:uid].succ : '1'
    else
      '1'
    end
    @dx.create({x: raw_entry.sub(/(#\w+)$/){|x| x.downcase}}, hashtag.downcase, custom_attributes: {uid: uid})
    [true, 'section added']
  end  
    
  def new_config()

    dir = Dir.pwd
    
    {
      dir: dir,
      urlbase: 'http://www.yourwebsitehere.org/liveblog/',
      edit_url: 'http://www.yourwebsitehere.org/do/liveblog/edit',
      css_url: '/liveblog/liveblog.css',
      xsl_path: File.join(dir, 'liveblog.xsl'),
      xsl_url: '/liveblog/liveblog.xsl',
      bannertext: '',
      title: "John Smith's LiveBlog",
      rss_title: "John Smith's LiveBlog",
      rss_lang: 'en_gb'
    }
  end
  
  # returns an array with a fractured date in the format [YYYY,mmm,dd]
  # e.g. #=> ['2015','apr','11']
  #
  def path(d=@d)
    [d.year.to_s, Date::MONTHNAMES[d.month].downcase[0..2], d.day.to_s]
  end

  # returns a string representing a date within a directory path
  # e.g. #=> 2015/apr/11/
  #  
  def urlpath(d=@d)
    path(d).join('/') + '/'
  end
  
  def static_urlpath(d=@d)      
    @urlbase.sub(/[^\/]$/,'\0/') + urlpath(d)
  end
      
  def save_html()
     
    formatted2_filepath = File.join(path(), 'formatted2.xml')
    FileUtils.cp File.join(path(), 'index.xml'), formatted2_filepath
    
    doc = Rexle.new File.read(formatted2_filepath)
    
    summary = doc.root.element('summary')
    
    summary.element('recordx_type').delete

    add summary, 'edit_url', "%s/%s" % [@edit_url, urlpath()]
    add summary, 'date',      @d.strftime("%d-%b-%Y").upcase
    add summary, 'day',   @d.strftime("%A")
    add summary, 'date_uri',   urlpath()
    add summary, 'css_url',   @css_url
    add summary, 'published', Time.now.strftime("%d-%m-%Y %H:%M")
    add summary, 'prev_day',  static_urlpath(@d-1)
    add summary, 'next_day', @d == Date.today ? '' : static_urlpath(@d+1)
    add summary, 'bannertext',   @bannertext
    add summary, 'link',  static_urlpath(@d)
  
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
    
    File.write formatted2_filepath, doc.xml(pretty: true)
        
    # save the related CSS file locally if the file doesn't already exist
    if not File.exists? 'liveblog.css' then
      FileUtils.cp File.join(File.dirname(__FILE__), 'liveblog.css'),\
                                                                 'liveblog.css'
    end
        
    raw_formatted_filepath = File.join(path(), 'raw_formatted.xml')  
    formatted_filepath = File.join(path(), 'formatted.xml')    
    
    unless File.exists? raw_formatted_filepath then

      doc2 = doc.root.deep_clone

      doc2.root.traverse do |node|
        node.attributes[:created] = Time.now.to_s
      end
      
      File.write raw_formatted_filepath, doc2.xml(pretty: true)
      
      return 
    end

    buffer = File.read(raw_formatted_filepath)
    buffer2 = File.read(formatted2_filepath)
    doc = RexleDiff.new(buffer, buffer2, fuzzy_match: true).to_doc

    File.write raw_formatted_filepath, doc.xml(pretty: true)

    doc.root.xpath('records/section/section').each do |node|

      node.attributes[:created] ||= Time.now.to_s
      t = Time.parse(node.attributes[:created]) 
      element = Rexle::Element.new('time', value: t.strftime("%-I:%M%P"), \
                                                 attributes: {class: 'border'})

      node.element('details/summary').add element
      
      node.xpath('//p').each do |e|

        e.attributes[:created] ||= Time.now.to_s
        t = Time.parse(e.attributes[:created])
        element = Rexle::Element.new('time', value: t.strftime("%-I:%M%P"), \
                                                 attributes: {class: 'border'})
        e.prepend element

      end      
    end

    render_html doc
    File.write formatted_filepath, doc.xml(pretty: true)
    
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
  
  def rss_timestamp(s)
    Time.parse(s).strftime("%a, %-d %b %Y %H:%M:%S %Z")
  end
  
  def save_rss()
    
    buffer = File.read File.join(path(), 'raw_formatted.xml')  
    doc = Rexle.new buffer
    
    summary = doc.root.element 'summary'

    dx = Dynarex.new 'liveblog[title,desc,link, pubdate, '\
        +  'lastbuild_date, lang]/entry(title, desc, created_at, uri, guid)'
    
    dx.title = @rss_title || 'LiveBlog'
    dx.desc = 'Latest LiveBlog posts fetched from ' + @urlbase
    dx.link = @urlbase
    dx.order = 'descending'
    dx.pubdate = rss_timestamp(summary.text('published'))
    dx.lastbuild_date = Time.now.strftime("%a, %-d %b %Y %H:%M:%S %Z")
    dx.lang = @rss_lang

    doc.root.xpath('records/section/section/details').each do |x|

      next if x.elements.empty?
      a = x.elements.to_a
      h1 = a.shift.element('h1')
      hashtag = h1.text[/#\w+$/]

      created_at = rss_timestamp(h1.attributes[:created])

      a.each do |node|

        node.attributes.delete :created
        node.attributes.delete :last_modified
        
        node.traverse do |x| 
          
          x.attributes.delete :created
          x.attributes.delete :last_modified

        end
      end

      uri = doc.root.element('summary/link/text()') + hashtag
      
      record = {
        title: h1.text,
        desc: a.map(&:xml).join("\n"),
        created_at: created_at,
        uri: uri,
        guid: uri
      }
      
      dx.create record
    end

    dx.xslt_schema = 'channel[title:title,description:desc,link:link,'\
        + 'pubDate:pubdate,lastBuildDate:lastbuild_date,language:lang]/'\
        + 'item(title:title,link:uri,description:desc,pubDate:created_at,'\
        + 'guid:guid)'
    File.write 'rss.xml', dx.to_rss
    
  end    
  
  def save_frontpage()

    # this method is still under developement. If the previous day's 
    # file doesn't exit it will simply return nil.
    begin
      
      doc, doc2 = [@d-1, @d].map do |d|

        url = @urlbase + d.strftime("%Y/%b/%d/formatted.xml")
        Rexle.new RXFHelper.read(url).first

      end
      
      doc2.root.add doc.root.element('records')
      File.write 'formatted.xml', doc2.xml
      
    rescue
      nil
    end
  end 
end