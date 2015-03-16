<?xml version="1.0" encoding="utf-8"?>
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
  
  
  <div id='summary'>
  <ul>
  <xsl:for-each select="records/section/section">
    <!--<xsl:sort select='../@id' order='descending'/>-->
     <li><a href='#{@id}'><xsl:value-of select='details/summary/h1'/></a></li>
  </xsl:for-each>  
  </ul>
  </div>
  <aside>
  <ul>
    <li><xsl:value-of select='summary/date'/></li>
    <li>
      <a href="{summary/edit_url}" rel="nofollow">edit</a>
    </li>      
    </ul>
  </aside>  
  <article>  
  <div style='clear:both'/>
  <xsl:for-each select="records/section">
     <!--<xsl:sort select='@id' order='descending'/>-->
     <xsl:copy-of select='section'/>

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
          <dt>Published:</dt><dd><xsl:value-of select="summary/published"/></dd>
        </dl>
      </footer>  
  </article>
  
  </body>
</html>
  </xsl:template>
</xsl:stylesheet>
