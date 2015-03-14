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
    <xsl:for-each select="records/section">
<xsl:text>
</xsl:text>
<xsl:copy-of select='section'/>

  <xsl:text>
</xsl:text>
    </xsl:for-each>
  </body>
</html>
  </xsl:template>
</xsl:stylesheet>