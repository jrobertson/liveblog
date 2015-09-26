xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="utf-8" indent="yes" />

  <xsl:template match="*">
<xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
<html>
  <head>
    <title><xsl:value-of select='summary/title'/></title>
    <link rel='stylesheet' type='text/css' href='{summary/css_url}' media='screen, projection, tv, print'/>
  </head>
  <body>
  <div id="wrap">
  <header>
    <nav>
      <ul>
        <li>
          <a href="/">home</a>
        </li>
        <li>
          <a href="/liveblog">liveblog</a>
        </li>
      </ul>
    </nav>
  </header>
  
  <xsl:if test='summary/bannertext'>
    <p><xsl:value-of select='summary/bannertext'/></p>
  </xsl:if>
  
  <div id='summary'>
  <ul>
  <xsl:for-each select="records/section">
    <!--<xsl:sort select='../@id' order='descending'/>-->
     <li><a href='#{@id}'><xsl:value-of select='details/summary/h1'/></a></li>
  </xsl:for-each>  
  </ul>
  </div>
  <aside>
  <ul>
    <li>
      <xsl:value-of select='summary/date'/>      
    </li>
    <li>
      <xsl:value-of select='summary/day'/>
    </li>    
    <li>
      <a href='{summary/prev_day}' class='arrow'>&#8592;</a>
      <xsl:element name="a">
        <xsl:choose>
        <xsl:when test="summary/next_day != ''">
          <xsl:attribute name="class">arrow</xsl:attribute>
         </xsl:when>
         <xsl:otherwise>
           <xsl:attribute name="class">deadarrow</xsl:attribute>
         </xsl:otherwise>
         </xsl:choose>
        <xsl:attribute name="href"><xsl:value-of select="summary/next_day"/></xsl:attribute>
         &#8594;
      </xsl:element>
    </li>    
    <li>
      <a href="{summary/edit_url}" rel="nofollow">edit</a>
    </li>      
    </ul>
  </aside>  
  <article>  
  <div style='clear:both'/>
  <xsl:for-each select="records/section">
     <!--<xsl:sort select='@id' order='descending'/>-->
     <xsl:copy-of select='.'/>

  </xsl:for-each>

      <footer>
        <dl id="info">
          <dt>Tags:</dt>
          <dd>
          <ul>
          <xsl:for-each select="summary/tags/*">
            <li><xsl:value-of select="."/></li>
          </xsl:for-each>
          </ul>
          </dd>
          <dt>Source:</dt>
          <dd><a href="index.txt">index.txt</a></dd>
          <dt>XML:</dt>
          <dd><a href="formatted.xml">formatted.xml</a></dd>          
          <dt>Published:</dt><dd><xsl:value-of select="summary/published"/></dd>
        </dl>
      </footer>  
  </article>
  </div>
  </body>
</html>
  </xsl:template>
</xsl:stylesheet>