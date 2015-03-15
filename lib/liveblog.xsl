<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="utf-8" indent="yes" />

  <xsl:template match="*">
<xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
<html>
  <head>
    <title><xsl:value-of select='summary/title'/></title>
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
  <div>
    <ul>
      <li>
        <a href="{summary/edit_url}">edit</a>
      </li>
    </ul>
  </div>
  
  <h1><xsl:value-of select='summary/date'/></h1>
  
  <xsl:for-each select="records/section/section">

     <xsl:copy-of select='.'/>

  </xsl:for-each>
  </body>
</html>
  </xsl:template>
</xsl:stylesheet>
