<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:func="http://exslt.org/functions"
				xmlns:my="urn:my-functions"
                xmlns:date="http://exslt.org/dates-and-times"
                xmlns:math="http://exslt.org/math"
				extension-element-prefixes="func date"
                >

  <xsl:template match="/">
     <root>
        <function><xsl:value-of select="my:func()"/></function>
        <date><xsl:value-of select="date:date()"/></date>
        <max><xsl:value-of select="math:max(//max/value)"/></max>
     </root>
  </xsl:template>

  <func:function name="my:func">
	<func:result select="'func-result'"/>
  </func:function>

</xsl:stylesheet>
