#!/usr/bin/env ruby

# file: liveblog.rb

require 'time'
require 'fileutils'
require 'dxsectionx'
require 'simple-config'
require 'rexle-diff'

class LiveBlog

  # the config can either be a hash, a config filepath, or nil
  #
  def initialize(x=nil, config: nil, date: Date.today, plugins: {})        
    
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

    @dir, @urlbase, @edit_url, @css_url, @xsl_path, @xsl_today_path, \
            @xsl_url, @bannertext, @title, @rss_title, @rss_lang, \
            @hyperlink_today, plugins = \
     (%i(dir urlbase edit_url css_url xsl_path xsl_today_path xsl_url) \
              + %i( bannertext title rss_title rss_lang hyperlink_today ) \
              + %i(plugins)).map{|x| h[x]}

    @title ||= 'LiveBlog'
    @rss_lang ||= 'en-gb'
    
    Dir.chdir @dir    

    @d = date
    dxfile = File.join(path(), 'index.xml')
    
    @plugins = initialize_plugins(plugins || [])

    if File.exists? dxfile then 
    
      @dx = Dynarex.new(dxfile)
      @d = Date.parse @dx.title
      
    else
      
      new_day()        
      
    end
    

  end
  
  # add a single line entry
  #
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
    entry = raw_entry.length > len ? "%s... %s" % [raw_entry.slice(0, len),\
                                                           hashtag] : raw_entry
    message = "%s %s#%s" % [entry, static_urlpath(), hashtag]
    
    [true, message]
  end
  
  # returns a RecordX object for a given hashtag
  #
  def find_hashtag(hashtag)    
    @dx.find hashtag[/\w+$/]
  end
  
  def initialize_plugins(plugins)
    
    plugins.inject([]) do |r, plugin|
      
      name, settings = plugin
      return r if settings[:active] == false and !settings[:active]
      
      klass_name = 'LiveBlogPlugin' + name.to_s

      r << Kernel.const_get(klass_name).new(settings: settings, \
           variables: {filepath: @dir, todays_filepath: path(@d), \
                                                   urlbase: @urlbase })

    end
        
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
  
  def new_day(date: Date.today)
    
    @d = date
    dxfile = File.join(path(), 'index.xml')
    
    new_file()
    link_today()

    @plugins.each do |x|
      
      if x.respond_to? :on_new_day then
        
        yesterdays_index_file = File.join(path(@d-1), 'index.xml')

        x.on_new_day(yesterdays_index_file, urlpath(@d-1))
        
      end
      
    end      
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

    @dx.import(s) {|x| sanitise x } 
    
    @dx.xpath('records/section').each do |rec|
      
      rec.attributes[:uid] = rec.attributes[:id]
      rec.attributes[:id] = rec.text('x').lines.first[/#(\w+)$/,1]

    end
    
    @dx.instance_variable_set :@dirty_flag, true

    save()
    
  end
  
  alias import new_file  
  
  def raw_view(tag)
    r = self.find_hashtag tag
    r.x if r
  end
  
  def save()

    @dx.save File.join(path(), 'index.xml')

    File.write File.join(path(), 'index.txt'), @dx.to_s
    save_html()
    save_rss()
    save_frontpage()
    FileUtils.cp File.join(path(),'raw_formatted.xml'), \
                                    File.join(path(),'raw_formatted.xml.bak')

  end      
  
  def update(val)
    self.method(val[/^<\?dynarex/] ? :import : :update_entry).call val
  end
  
  # update a page (contains multiple liveblog entries for a section) entry
  #
  def update_entry(raw_entry)
    
    hashtag = raw_entry.lines.first[/#(\w+)$/,1]

    record_found = find_hashtag hashtag
    
    if record_found then
      
      record_found.x = sanitise raw_entry
      save()

      @plugins.each do |x|
        
        if x.respond_to? :on_update_entry then
          x.on_update_section(raw_entry, hashtag) 
        end
        
      end      
      [true]
    else
      [false, 'record for #' + hashtag + ' not found.']
    end
    
  end
  
  
  private

  
  def add_section_entry(raw_entry, hashtag)
    
    rec = @dx.find hashtag
    
    return [false, 'rec not found'] unless rec

    entry = sanitise raw_entry.chomp
    rec.x += "\n\n" + entry + "\n"
    
    @plugins.each do |x|

      if x.respond_to? :on_new_section_entry then
        x.on_new_section_entry(raw_entry, hashtag) 
      end
      
    end
    
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

    @dx.create({x: raw_entry.sub(/(#\w+)$/){|x| x.downcase}}, \
                           id: hashtag.downcase, custom_attributes: {uid: uid})
    
    @plugins.each do |x|
      x.on_new_section(raw_entry, hashtag) if x.respond_to? :on_new_section
    end
    
    [true, 'section added']
  end  
  
  # used by the sanitise method
  #
  def code2indent(s2)

    # find the beginning
    x1 = s2 =~ /^```/    
    return s2 unless x1

    # find the end
    x2 = s2[x1+3..-1] =~ /^```/
    return s2 unless x2
    
    codeblock = s2[x1+3..x1+x2+2]

    s3 = s2[0..x1-1] + codeblock.lines.map{|x| x.prepend(' ' * 4)}.join + \
        "\n" + s2[x1+x2+6..-1]

    return code2indent(s3)

  end
  
    
  def new_config()

    dir = Dir.pwd
    
    {
      dir: dir,
      urlbase: 'http://www.yourwebsitehere.org/liveblog/',
      edit_url: 'http://www.yourwebsitehere.org/do/liveblog/edit',
      css_url: '/liveblog/liveblog.css',
      xsl_path: File.join(dir, 'liveblog.xsl'),
      xsl_today_path: File.join(dir, 'liveblog_today.xsl'),
      xsl_url: '/liveblog/liveblog.xsl',
      hyperlink_today: 'http://yourwebsite.org/go_to_today',
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
  
  def sanitise(raw_s)
    
    # Transform any code encapsulated within 3 backticks to the 
    # 4 spaces indented style. This prevents Ruby comments being 
    # wrongfully identified as a sectionx heading.
    
    code2indent(raw_s)

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
    add summary, 'hyperlink_today',  @hyperlink_today
  
    tags = Rexle::Element.new('tags')
    
    doc.root.xpath('records/section/x/text()').each do |x|

      tags.add Rexle::Element.new('tag').add_text x.lines.first.rstrip[/#(\w+)$/,1]\
                                                                      .downcase
    end
    
    summary.add tags
    
    domain = @urlbase[/https?:\/\/([^\/]+)/,1].split('.')[-2..-1].join('.')

    dxsx = DxSectionX.new(doc,  domain: domain, xsl_url: @xsl_url)
    xmldoc = dxsx.to_doc

    File.write formatted2_filepath, xmldoc.xml(pretty: true)
        
    # save the related CSS file locally if the file doesn't already exist
    if not File.exists? 'liveblog.css' then
      FileUtils.cp File.join(File.dirname(__FILE__), 'liveblog.css'),\
                                                                 'liveblog.css'
    end
        
    raw_formatted_filepath = File.join(path(), 'raw_formatted.xml')  
    formatted_filepath = File.join(path(), 'formatted.xml')    
    
    unless File.exists? raw_formatted_filepath then

      doc2 = xmldoc.root.deep_clone

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

    doc.root.xpath('records/section').each do |node|

      node.attributes[:created] ||= Time.now.to_s
      #t = Time.parse(node.attributes[:last_modified].empty? ? \
      #               node.attributes[:created] : node.attributes[:last_modified])
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
      
      node.xpath('//h2').each do |h2|
        h2.attributes[:id] = node.attributes[:id] \
            + Time.parse(h2.attributes[:created]).strftime("%H%M")
      end      
    end
    
    related_links_filepath = File.join(path(), 'related_links.xml')  
    
    if File.exists? related_links_filepath then
      
      related_links = Rexle::Element.new 'related_links'
      doc2 = Rexle.new(File.read(related_links_filepath))
      doc2.root.xpath('body/*').each {|element| related_links.add element }
        
      doc.root.add related_links
    end

    @plugins.each {|x| x.on_doc_update(doc) if x.respond_to? :on_doc_update }

    render_html doc, xsl: @xsl_today_path
    File.write formatted_filepath, doc.xml(pretty: true)
    
  end

  def ordinalize(n)
    n.to_s + ( (10...20).include?(n) ? 'th' : 
              %w{ th st nd rd th th th th th th }[n % 10] )
  end  

  def add(summary, name, s)
    summary.add Rexle::Element.new(name).add_text s
  end
  
  def render_html(doc, d=@d, xsl: @xsl_path)

    xslt_buffer = if xsl then
      buffer, _ = RXFHelper.read xsl
      buffer
    else
      lib = File.exists?('liveblog.xsl') ? '.' : File.dirname(__FILE__)
      File.read(File.join(lib,'liveblog.xsl'))
    end

    #jr270327 xslt  = Nokogiri::XSLT(xslt_buffer)
    #jr270327 out = xslt.transform(Nokogiri::XML(doc.xml))
    out = Rexslt.new(xslt_buffer, doc.xml).to_s
    File.write File.join(path(d), 'index.html'), \
            out.to_s.gsub(/\s+(?=<\/?(?:pre|code)>)/,'')  
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
    
    doc.root.xpath('records/section/details').each do |x|

      next if x.elements.empty? or x.element('summary').elements.empty?
      a = x.elements.to_a
      h1 = a.shift.element('h1')
      hashtag = h1.text[/#\w+$/]

      next unless h1.attributes[:created]
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
    # file doesn't exist it will simply return nil.
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
