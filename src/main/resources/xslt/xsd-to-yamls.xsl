<?xml version="1.0" encoding="UTF-8"?>
<!--

    Copyright © 2018 Mayo Clinic (RSTKNOWLEDGEMGMT@mayo.edu)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x2y="http://www.mayo.edu/kmdp/xsd2yamls" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:catalog="urn:oasis:names:tc:entity:xmlns:xml:catalog:uri" version="3.0">

  <xsl:param name="CATALOGS" as="xs:string"/>

  <xsl:variable name="tab" select="2" as="xs:integer"/>

  <xsl:output method="text" indent="no"/>
  <xsl:template match="text() | @*"/>


  <xsl:template name="main" match="/">
    <xsl:text>swagger: "2.0"</xsl:text>
    <xsl:text>&#xA;</xsl:text>
    <xsl:text>definitions:</xsl:text>
    <xsl:text>&#xA;</xsl:text>
    <xsl:call-template name="innerTypes"/>
    <xsl:call-template name="innerSimpleTypes"/>
  </xsl:template>


  <xsl:template name="innerTypes">
    <xsl:for-each select="//xs:complexType">
      <xsl:variable name="indent" select="$tab" as="xs:integer"/>
      <xsl:variable name="isExtension" select="exists(.//xs:extension)"/>
      <xsl:variable name="type" select="xs:QName(@name)" as="xs:QName"/>

      <xsl:value-of select="x2y:blanks($indent)"/>
      <xsl:value-of select="concat(@name, ':')"/>
      <xsl:text>&#xA;</xsl:text>

      <xsl:if test="$isExtension">
        <xsl:call-template name="parent">
          <xsl:with-param name="indent" select="$indent + $tab"/>
          <xsl:with-param name="base" select=".//xs:extension"/>
        </xsl:call-template>
      </xsl:if>


      <xsl:call-template name="typeDefinition">
        <xsl:with-param name="extension" select="$isExtension"/>
        <xsl:with-param name="indent"
          select="
            if ($isExtension) then
              ($indent + 2 * $tab)
            else
              ($indent + $tab)"
        />
        <xsl:with-param name="extensible" select="local-name-from-QName($type)='Map'"/>
      </xsl:call-template>

      <xsl:call-template name="xmlBinding">
        <xsl:with-param name="isAttribute" select="false()"/>
        <xsl:with-param name="indent"
          select="
            if ($isExtension) then
              ($indent + 2 * $tab)
            else
              ($indent)"
        />
        <xsl:with-param name="type" select="$type"/>
      </xsl:call-template>

    </xsl:for-each>
  </xsl:template>

  <xsl:template name="typeDefinition">
    <xsl:param name="extension" as="xs:boolean"/>
    <xsl:param name="indent" as="xs:integer"/>
    <xsl:param name="extensible" as="xs:boolean?"/>

    <xsl:value-of select="x2y:blanks($indent)"/>
    <xsl:if test="$extension">- </xsl:if>
    <xsl:text>type: object</xsl:text>
    <xsl:text>&#xA;</xsl:text>

    <xsl:variable name="propIndent"
      select="
        $indent + (if ($extension) then
          $tab
        else
          0)"
      as="xs:integer"/>

    <xsl:value-of select="x2y:blanks($propIndent)"/>
    <xsl:text>discriminator: _class</xsl:text>
    <xsl:text>&#xA;</xsl:text>

    <xsl:value-of select="x2y:blanks($propIndent)"/>
    <xsl:text>properties:</xsl:text>
    <xsl:text>&#xA;</xsl:text>

    <xsl:value-of select="x2y:blanks($propIndent + $tab)"/>
    <xsl:text>_class : string</xsl:text>
    <xsl:text>&#xA;</xsl:text>

    <xsl:for-each select=".//xs:sequence/xs:element">
      <xsl:call-template name="xsd_elem">
        <xsl:with-param name="extension" select="$extension"/>
        <xsl:with-param name="indent" select="$propIndent + $tab"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:if test=".//xs:group/@ref">
      <xsl:variable name="grpRef" select=".//xs:group/@ref"/>
      <xsl:for-each select="//xs:group[@name=$grpRef]//xs:sequence/xs:element">
        <xsl:call-template name="xsd_elem">
          <xsl:with-param name="extension" select="$extension"/>
          <xsl:with-param name="indent" select="$propIndent + $tab"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>

    <xsl:for-each select=".//xs:attribute">
      <xsl:call-template name="xsd_attr">
        <xsl:with-param name="extension" select="$extension"/>
        <xsl:with-param name="indent" select="$propIndent + $tab"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:if test=".//xs:attributeGroup/@ref">
      <xsl:variable name="grpRef" select=".//xs:attributeGroup/@ref"/>
      <xsl:for-each select="//xs:attributeGroup[@name=$grpRef]//xs:attribute">
        <xsl:call-template name="xsd_attr">
          <xsl:with-param name="extension" select="$extension"/>
          <xsl:with-param name="indent" select="$propIndent + $tab"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>

    <xsl:call-template name="requireds">
      <xsl:with-param name="indent" select="$propIndent"/>
    </xsl:call-template>

    <xsl:if test="$extensible">
      <xsl:value-of select="x2y:blanks($propIndent)"/>
      <xsl:text>additionalProperties:</xsl:text>
      <xsl:text>&#xA;</xsl:text>
      <xsl:value-of select="x2y:blanks($propIndent + $tab)"/>
      <xsl:text>type: object</xsl:text>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>

  </xsl:template>

  <xsl:template name="parent">
    <xsl:param name="base" as="node()"/>
    <xsl:param name="indent" as="xs:integer"/>
    <xsl:variable name="baseType" select="resolve-QName($base/@base, $base)" as="xs:QName"/>

    <xsl:value-of select="x2y:blanks($indent)"/>
    <xsl:text>allOf:</xsl:text>
    <xsl:text>&#xA;</xsl:text>
    <xsl:value-of select="x2y:blanks($indent + $tab)"/>
    <xsl:text>- $ref: </xsl:text>
    <xsl:value-of select="x2y:getType($baseType, .)"/>
    <xsl:text>&#xA;</xsl:text>

  </xsl:template>

  <xsl:template name="xsd_attr">
    <xsl:param name="extension" as="xs:boolean"/>
    <xsl:param name="indent" as="xs:integer"/>
    <xsl:variable name="type" select="resolve-QName(@type, .)" as="xs:QName"/>

    <xsl:value-of select="x2y:blanks($indent)"/>
    <xsl:value-of select="concat(@name, ':')"/>
    <xsl:text>&#xA;</xsl:text>

    <xsl:value-of select="x2y:blanks($indent + $tab)"/>
    <xsl:text>type: </xsl:text>
    <xsl:value-of select="x2y:getType($type, .)"/>
    <xsl:text>&#xA;</xsl:text>

    <xsl:call-template name="xmlBinding">
      <xsl:with-param name="indent" select="$indent"/>
      <xsl:with-param name="type" select="$type"/>
      <xsl:with-param name="isAttribute" select="true()"/>
    </xsl:call-template>

  </xsl:template>

  <xsl:template name="xsd_elem">
    <xsl:param name="extension"/>
    <xsl:param name="indent" as="xs:integer"/>
    <xsl:variable name="type" select="resolve-QName(@type, .)" as="xs:QName"/>

    <xsl:value-of select="x2y:blanks($indent)"/>
    <xsl:value-of select="concat(@name, ':')"/>
    <xsl:text>&#xA;</xsl:text>

    <xsl:value-of select="x2y:blanks($indent + $tab)"/>
    <xsl:choose>
      <xsl:when test="x2y:isArray(.)">
        <xsl:value-of select="'type: array'"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:value-of select="x2y:blanks($indent + $tab)"/>
        <xsl:value-of select="'items:'"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:value-of select="x2y:blanks($indent + 2*$tab)"/>
        <xsl:value-of select="concat(x2y:typeOrRef($type), ': ')"/>
        <xsl:value-of select="x2y:getType($type, .)"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat(x2y:typeOrRef($type), ': ')"/>
        <xsl:value-of select="x2y:getType($type, root())"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="x2y:isArray(.)">
      <xsl:if test="@minOccurs">
        <xsl:value-of select="x2y:blanks($indent + $tab)"/>
        <xsl:value-of select="'minItems: '"/>
        <xsl:value-of select="@minOccurs"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:if>

      <xsl:if test="number(@maxOccurs)">
        <xsl:value-of select="x2y:blanks($indent + $tab)"/>
        <xsl:value-of select="'maxItems: '"/>
        <xsl:value-of select="@maxOccurs"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:if>
    </xsl:if>

    <xsl:call-template name="xmlBinding">
      <xsl:with-param name="indent" select="$indent"/>
      <xsl:with-param name="type" select="$type"/>
      <xsl:with-param name="isAttribute" select="false()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="requireds">
    <xsl:param name="indent" as="xs:integer"/>

    <xsl:value-of select="x2y:blanks($indent)"/>
    <xsl:text>required:</xsl:text>
    <xsl:text>&#xA;</xsl:text>

    <xsl:value-of select="x2y:blanks($indent + $tab)"/>
    <xsl:text>- _class</xsl:text>
    <xsl:text>&#xA;</xsl:text>

    <xsl:for-each select=".//xs:attribute[@use = 'required']">
      <xsl:value-of select="x2y:blanks($indent + $tab)"/>
      <xsl:value-of select="concat('- ', @name)"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
    <xsl:if test=".//xs:attributeGroup/@ref">
      <xsl:variable name="grpRef" select=".//xs:attributeGroup/@ref"/>
      <xsl:for-each select="//xs:attributeGroup[@name=$grpRef]//xs:attribute[@use = 'required']">
        <xsl:value-of select="x2y:blanks($indent + $tab)"/>
        <xsl:value-of select="concat('- ', @name)"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:for-each>
    </xsl:if>

    <xsl:for-each select=".//xs:sequence/xs:element[@minOccurs > 0]">
      <xsl:value-of select="x2y:blanks($indent + $tab)"/>
      <xsl:value-of select="concat('- ', @name)"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
    <xsl:if test=".//xs:group/@ref">
      <xsl:variable name="grpRef" select=".//xs:group/@ref"/>
      <xsl:for-each select="//xs:group[@name=$grpRef]//xs:sequence/xs:element[@minOccurs > 0]">
        <xsl:value-of select="x2y:blanks($indent + $tab)"/>
        <xsl:value-of select="concat('- ', @name)"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:for-each>
    </xsl:if>

  </xsl:template>

  <xsl:template name="xmlBinding">
    <xsl:param name="indent" as="xs:integer"/>
    <xsl:param name="type" as="xs:QName"/>
    <xsl:param name="isAttribute" as="xs:boolean"/>
    <xsl:variable name="mainTNS" select="root(.)//xs:schema/@targetNamespace"/>

    <xsl:value-of select="x2y:blanks($indent + $tab)"/>
    <xsl:text>xml:</xsl:text>
    <xsl:text>&#xA;</xsl:text>

    <xsl:if test="$isAttribute">
      <xsl:value-of select="x2y:blanks($indent + 2 * $tab)"/>
      <xsl:text>attribute: true</xsl:text>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>

    <xsl:if test="not($isAttribute)">
      <xsl:variable name="ns">
        <xsl:choose>
          <xsl:when test="namespace-uri-from-QName($type) != ''">
            <xsl:value-of select="namespace-uri-from-QName($type)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$mainTNS"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:value-of select="x2y:blanks($indent + 2 * $tab)"/>
      <xsl:value-of select="concat('namespace: ', '''', $ns, '''')"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="innerSimpleTypes">

    <xsl:for-each
      select="//xs:simpleType[exists(xs:restriction[@base = 'xs:string'])]">
      <xsl:variable name="indent" select="$tab" as="xs:integer"/>
      <xsl:variable name="type" select="xs:QName(@name)" as="xs:QName"/>

      <xsl:value-of select="x2y:blanks($indent)"/>
      <xsl:value-of select="concat(@name, ':')"/>
      <xsl:text>&#xA;</xsl:text>

      <xsl:value-of select="x2y:blanks($indent + $tab)"/>
      <xsl:text>type: string</xsl:text>
      <xsl:text>&#xA;</xsl:text>

      <xsl:if test="exists(.//xs:enumeration)">
        <xsl:value-of select="x2y:blanks($indent + $tab)"/>
        <xsl:text>enum:</xsl:text>
        <xsl:text>&#xA;</xsl:text>


        <xsl:for-each select=".//xs:enumeration">
          <xsl:value-of select="x2y:blanks($indent + 2 * $tab)"/>
          <xsl:value-of select="concat('- ', @value)"/>
          <xsl:text>&#xA;</xsl:text>
        </xsl:for-each>
      </xsl:if>


      <xsl:call-template name="xmlBinding">
        <xsl:with-param name="isAttribute" select="false()"/>
        <xsl:with-param name="indent" select="$indent"/>
        <xsl:with-param name="type" select="$type"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>


  <xsl:function name="x2y:getRefURI" as="xs:anyURI?">
    <xsl:param name="type" as="xs:QName"/>
    <xsl:param name="ctx" as="node()"/>
    <xsl:choose>
      <xsl:when test="x2y:isAlien($type, $ctx)">
        <xsl:variable name="ns" select="namespace-uri-from-QName($type)"/>
        <xsl:value-of select="x2y:mapNamespace($ns, $ctx)"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:function>


  <xsl:function name="x2y:mapNamespace" as="xs:anyURI?">
    <xsl:param name="uri" as="xs:anyURI"/>
    <xsl:param name="ctx" as="node()"/>
    <xsl:choose>
      <xsl:when test="root($ctx)//xs:import[@namespace = $uri and @schemaLocation]">
        <xsl:variable name="schemaLoc"
          select="root($ctx)//xs:import[@namespace = $uri]/@schemaLocation"/>
        <xsl:value-of select="replace($schemaLoc, '.xsd$', '.yaml')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="tokenize($CATALOGS, ',')">
          <xsl:variable name="CATALOG" select="."/>
          <xsl:variable name="catalogURI"
            select="replace(replace($CATALOG, '\\', '/'), '//', '/')"/>
          <xsl:variable name="mappedURI" select="doc($catalogURI)//*[@name = $uri][1]/@uri"/>
          <!--xsl:message select="concat($catalogURI, ' resolved ', $uri, ' as ', fn:string-join($mappedURI) )"/-->
          <xsl:if test="$mappedURI != ''">
            <xsl:variable name="schemaLoc"
              select="x2y:makeRelative(resolve-uri($mappedURI, $catalogURI), document-uri(root($ctx)))"/>
            <xsl:value-of select="replace($schemaLoc, '.xsd$', '.yaml')"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>


  <xsl:function name="x2y:isAlien" as="xs:boolean">
    <xsl:param name="type" as="xs:QName"/>
    <xsl:param name="ctx" as="node()"/>
    <xsl:variable name="ns" select="namespace-uri-from-QName($type)"/>
    <xsl:variable name="mainTNS" select="root($ctx)//xs:schema/@targetNamespace"/>
    <xsl:sequence select="$ns != 'http://www.w3.org/2001/XMLSchema' and $ns != $mainTNS"/>
  </xsl:function>

  <xsl:function name="x2y:getType" as="xs:string">
    <xsl:param name="type" as="xs:QName"/>
    <xsl:param name="ctx" as="node()"/>
    <xsl:choose>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'int')">
        <xsl:text>number</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'integer')">
        <xsl:text>number</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'decimal')">
        <xsl:text>number</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'boolean')">
        <xsl:text>boolean</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'time')">
        <xsl:text>string</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'date')">
        <xsl:text>string</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'dateTime')">
        <xsl:text>string</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'string')">
        <xsl:text>string</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'token')">
        <xsl:text>string</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'anyURI')">
        <xsl:text>string</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'QName')">
        <xsl:text>string</xsl:text>
      </xsl:when>
      <xsl:when test="$type = QName('http://www.w3.org/2001/XMLSchema', 'hexBinary')">
        <xsl:text>string</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="concat('''', x2y:getRefURI($type, $ctx), '#/definitions/', local-name-from-QName($type), '''')"
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="x2y:blanks" as="xs:string">
    <xsl:param name="n" as="xs:integer"/>
    <xsl:sequence select="
        string-join(for $i in 1 to $n
        return
          ' ')"/>
  </xsl:function>

  <xsl:function name="x2y:typeOrRef" as="xs:string">
    <xsl:param name="type" as="xs:QName"/>
    <xsl:value-of>
      <xsl:choose>
        <xsl:when test="namespace-uri-from-QName($type) = 'http://www.w3.org/2001/XMLSchema'">type</xsl:when>
        <xsl:otherwise>$ref</xsl:otherwise>
      </xsl:choose>
    </xsl:value-of>
  </xsl:function>


  <xsl:function name="x2y:makeRelative">
    <xsl:param name="location" as="xs:string"/>
    <xsl:param name="origin" as="xs:string"/>

    <xsl:choose>
      <xsl:when test="$location != ''">

        <xsl:variable name="tgt" select="tokenize($location, '/')"/>
        <xsl:variable name="src" select="tokenize($origin, '/')"/>

        <xsl:variable name="base" select="tokenize(x2y:commonRoot($src, $tgt), ' ')"/>

        <xsl:variable name="rest" select="subsequence($tgt, count($base) + 1)"/>

        <xsl:variable name="backSteps" select="count($src) - count($base) - 1"/>
        <xsl:variable name="sequence"
          select="
            insert-before($rest, 0, for $i in (1 to $backSteps)
            return
              '..')"/>

        <xsl:value-of select="string-join($sequence, '/')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="''"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="x2y:commonRoot" as="xs:string*">
    <xsl:param name="arg1" as="xs:string*"/>
    <xsl:param name="arg2" as="xs:string*"/>
    <xsl:choose>
      <xsl:when test="$arg1[1] = $arg2[1]">
        <xsl:value-of
          select="
            insert-before(
            x2y:commonRoot(subsequence($arg1, 2), subsequence($arg2, 2)),
            0,
            $arg1[1])"
        />
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="x2y:isArray" as="xs:boolean">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="number($node/@minOccurs) > 1 or string($node/@maxOccurs) = 'unbounded'"/>
  </xsl:function>


</xsl:stylesheet>
