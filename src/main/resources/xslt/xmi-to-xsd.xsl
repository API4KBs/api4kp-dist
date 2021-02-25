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
  xmlns:xmi="http://www.omg.org/spec/XMI/20131001" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:uml="http://www.eclipse.org/uml2/5.0.0/UML" xmlns:xmi2xsd="http://www.mayo.edu/kmdp/xmi2xsd"
  xsi:schemaLocation="http://www.w3.org/1999/XSL/Transform
                                    https://www.w3.org/TR/xslt-30/schema-for-xslt30.xsd"
  xmi:version="2.5" version="3.0">

  <xsl:import href="hrefResolver.xsl"/>

  <xsl:param name="targetFolder"/>
  <xsl:param name="includedPackages" as="xs:string?"/>

  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="text() | @*"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Create schema element -->
  <xsl:template match="//uml:Model">
    <xsl:for-each select="//packagedElement[@xmi:type = 'uml:Package' 
                                            and xmi2xsd:shouldIncludePackage(.,$includedPackages)]">
      <xsl:if test="./packagedElement[@xmi:type = 'uml:Class' or @xmi:type = 'uml:DataType']">

        <xsl:variable name="path" select="xmi2xsd:packageToSchemaLocation(., ())"/>
        <xsl:result-document href="{concat(xmi2xsd:toFolderURI($targetFolder),$path)}" method="xml">
          <xsl:element name="xs:schema">
            <xsl:attribute name="elementFormDefault">qualified</xsl:attribute>

            <!-- Declare Namespaces -->
            <xsl:namespace name="" select="xmi2xsd:namespaceURI(.)"/>
            <xsl:attribute name="targetNamespace" select="xmi2xsd:namespaceURI(.)"/>
            <xsl:namespace name="xmi">http://www.omg.org/spec/XMI/20131001</xsl:namespace>

            <xsl:call-template name="resolveImports">
              <xsl:with-param name="root" select="."/>
            </xsl:call-template>

            <!-- Process Elements -->
            <xsl:call-template name="types">
              <xsl:with-param name="root" select="."/>
            </xsl:call-template>

          </xsl:element>
        </xsl:result-document>
      </xsl:if>
    </xsl:for-each>

  </xsl:template>


  <!-- for each Class, 
    create a named typed element, and a complex type -->
  <xsl:template name="types">
    <xsl:param name="root"/>

    <xsl:for-each
      select="$root/packagedElement[@xmi:type = 'uml:Class']">
      <xsl:if test="not(@name='Any')">
        <xsl:call-template name="namedElement"/>
      </xsl:if>
      <xsl:call-template name="complexType"/>
      <xsl:call-template name="classContent"/>
    </xsl:for-each>

    <xsl:for-each
      select="$root/packagedElement[@xmi:type = 'uml:DataType']">
      <xsl:call-template name="simpleType"/>
    </xsl:for-each>

    <xsl:for-each
      select="$root/packagedElement[@xmi:type = 'uml:Enumeration' and exists(./ownedLiteral)]">
      <xsl:call-template name="enums"/>
    </xsl:for-each>
  </xsl:template>


  <xsl:template name="namedElement">
    <xsl:element name="xs:element">
      <xsl:attribute name="name">
        <xsl:value-of select="concat(lower-case(substring(@name, 1, 1)), substring(@name, 2))"/>
      </xsl:attribute>

      <xsl:attribute name="type">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- Complex types: check inheritance, then generate class content -->

  <xsl:template name="complexType">
    <xsl:element name="xs:complexType">
      <xsl:copy-of select="@xmi:id"/>

      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>

      <xsl:if test="@isAbstract">
        <xsl:attribute name="abstract">true</xsl:attribute>

        <xsl:variable name="base" select="."/>
        <xsl:variable name="childrenIds" select="xmi2xsd:getDescendantIds($base)"/>
        <xsl:if test="exists($childrenIds)">
          <xsl:element name="xs:annotation">
            <xsl:element name="xs:appinfo">
              <xsl:element name="subTypes">
                <xsl:for-each select="$childrenIds">
                  <xsl:variable name="info"
                    select="xmi2xsd:getInternalTypeInfo(current(), root($base)//node()[@xmi:id = current()])"/>
                  <xsl:element name="subType">
                    <xsl:attribute name="name" select="map:get($info, 'name')"/>
                    <xsl:attribute name="type" select="concat('tns:',map:get($info, 'type'))"/>
                    <xsl:attribute name="about" select="map:get($info, 'conceptUri')"/>
                  </xsl:element>
                </xsl:for-each>
              </xsl:element>
            </xsl:element>
          </xsl:element>
        </xsl:if>

      </xsl:if>

      <xsl:choose>
        <!-- check for in-package generalizations -->
        <!-- parent ID must resolve to a class -->
        <!-- TODO multiple inheritance is not supported yet -->
        <xsl:when
          test="
            //packagedElement[@xmi:id = current()/generalization/@general
            and (@xmi:type = 'uml:Class' or @xmi:type = 'uml:DataType')]">

          <xsl:variable name="parentId" select="generalization/@general"/>
          <xsl:element name="xs:complexContent">
            <xsl:element name="xs:extension">
              <xsl:call-template name="injectType">
                <xsl:with-param name="type" select="xmi2xsd:resolveType(., $parentId)"/>
                <xsl:with-param name="typeAttr">base</xsl:with-param>
              </xsl:call-template>

              <xsl:call-template name="classContentRef"/>
            </xsl:element>
          </xsl:element>
        </xsl:when>

        <xsl:when
          test="
            ./generalization
            /general[(@xmi:type = 'uml:Class' or @xmi:type = 'uml:DataType')
            and @href]">

          <xsl:element name="xs:complexContent">
            <xsl:variable name="ext" select="xmi2xsd:resolveExternalType(generalization/general)"/>
            <!--<xsl:element name="{if (./templateBinding) then 'xs:restriction' else 'xs:extension'}">-->
            <xsl:element name="xs:extension">
              <xsl:attribute name="base" select="map:get($ext, 'type')"/>
              <xsl:namespace name="{map:get($ext,'pfx')}" select="map:get($ext, 'tns')"/>

              <xsl:call-template name="classContentRef"/>

            </xsl:element>
          </xsl:element>
        </xsl:when>
        <!-- primitive class with no generalizations -->
        <xsl:otherwise>
          <xsl:call-template name="classContentRef"/>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:element>
  </xsl:template>

  <xsl:template name="injectType">
    <xsl:param name="type" as="xs:QName"/>
    <xsl:param name="typeAttr"/>

    <xsl:choose>
      <xsl:when test="namespace-uri-from-QName($type)">
        <xsl:namespace name="tns" select="namespace-uri-from-QName($type)"/>
        <xsl:attribute name="{$typeAttr}">
          <xsl:value-of select="concat('tns:', local-name-from-QName($type))"/>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="{$typeAttr}">
          <xsl:value-of select="local-name-from-QName($type)"/>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- Complex content : primitive types -> XSD attributes; else -> elements -->
  <xsl:template name="classContentRef">
    <xsl:element name="xs:group">
      <xsl:attribute name="ref" select="xmi2xsd:contentGroupName(.)"/>
    </xsl:element>
    <xsl:element name="xs:attributeGroup">
      <xsl:attribute name="ref" select="xmi2xsd:attrGroupName(.)"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="classContent">
    <xsl:element name="xs:group">
      <xsl:attribute name="name" select="xmi2xsd:contentGroupName(.)"/>
      <xsl:call-template name="processElements"/>
    </xsl:element>
    <xsl:element name="xs:attributeGroup">
      <xsl:attribute name="name" select="xmi2xsd:attrGroupName(.)"/>
      <xsl:call-template name="processAttributes"/>
    </xsl:element>
  </xsl:template>


  <!-- Elements derive from associations and non-primitive UML attributes -->
  <xsl:template name="processElements">
    <xsl:element name="xs:sequence">
      <xsl:choose>
        <xsl:when test="not(@name='Map')">
          <xsl:call-template name="processComplexAttributes"/>
          <xsl:call-template name="processAssociations"/>
        </xsl:when>
        <xsl:otherwise>

          <!--<xsl:element name="xs:element">-->
          <!--<xsl:attribute name="minOccurs" select="0"/>-->
          <!--<xsl:attribute name="maxOccurs" select="'unbounded'"/>-->
          <!--<xsl:attribute name="type" select="'xs:anyType'" />-->
          <!--<xsl:attribute name="name" select="'property'" />-->
          <!--</xsl:element>-->

          <xsl:element name="xs:any">
            <!--<xsl:attribute name="namespace" select="'##other'" />-->
            <xsl:attribute name="minOccurs" select="0"/>
            <xsl:attribute name="maxOccurs" select="'unbounded'"/>
            <xsl:attribute name="processContents" select="'lax'"/>
          </xsl:element>

        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <!-- Only generate XSD elements for UML navigable endpoints, 
    as owned by the UML associations
    Detects name, type and cardinality
  -->
  <xsl:template name="processAssociations">
    <xsl:variable name="this" select="./@xmi:id"/>
    <xsl:for-each
      select="
        //packagedElement[@xmi:type = 'uml:Association' and @navigableOwnedEnd]">
      <xsl:variable name="navigs" select="tokenize(@navigableOwnedEnd, ' ')"/>

      <xsl:for-each
        select="
          ./ownedEnd[
          (preceding-sibling::ownedEnd/@type = $this
          or following-sibling::ownedEnd/@type = $this)
          and exists(index-of(@xmi:id, $navigs))]">

        <xsl:element name="xs:element">
          <xsl:attribute name="name" select="@name"/>
          <xsl:call-template name="elementType"/>
          <xsl:call-template name="elementCardinality"/>
        </xsl:element>

      </xsl:for-each>

    </xsl:for-each>
  </xsl:template>


  <!-- primitive type attributes -->
  <xsl:template name="processAttributes">
    <xsl:for-each select="ownedAttribute[not(@isDerived = 'true')]">
      <xsl:if test="
          ./type[@xmi:type = 'uml:PrimitiveType']">
        <xsl:element name="xs:attribute">
          <xsl:attribute name="name">
            <xsl:value-of select="@name"/>
          </xsl:attribute>
          <xsl:if test="lowerValue[@value >= 1]">
            <xsl:attribute name="use">
              <xsl:text>required</xsl:text>
            </xsl:attribute>
          </xsl:if>

          <xsl:attribute name="type" select="xmi2xsd:resolvePrimitive(./type/@href)"/>

        </xsl:element>
      </xsl:if>
    </xsl:for-each>

    <xsl:variable name="entityIDAttribute" select="xmi2xsd:getResourceEntityIDAttribute(.)"
      as="xs:string?"/>
    <xsl:if test="exists($entityIDAttribute)">
      <xsl:if test="not( ownedAttribute[ @name=$entityIDAttribute ] )">
        <xsl:element name="xs:attribute">
          <xsl:attribute name="name">
            <xsl:value-of select="$entityIDAttribute"/>
          </xsl:attribute>
          <xsl:attribute name="use">
            <xsl:text>optional</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="type">xs:anyURI</xsl:attribute>
        </xsl:element>
      </xsl:if>
    </xsl:if>


  </xsl:template>


  <!-- Datatype attributes -->
  <xsl:template name="processComplexAttributes">
    <xsl:for-each select="ownedAttribute">

      <xsl:if test="not(./type[@xmi:type = 'uml:PrimitiveType'])">
        <xsl:element name="xs:element">
          <xsl:attribute name="name">
            <xsl:value-of select="@name"/>
          </xsl:attribute>
          <xsl:call-template name="elementCardinality"/>
          <xsl:call-template name="elementType"/>
        </xsl:element>

      </xsl:if>

    </xsl:for-each>
  </xsl:template>


  <xsl:template name="elementCardinality">
    <xsl:attribute name="minOccurs">
      <xsl:choose>
        <xsl:when test="not(./lowerValue) or ./lowerValue[not(@value)]">0</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="./lowerValue/@value"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
    <xsl:attribute name="maxOccurs">
      <xsl:choose>
        <xsl:when test="not(./upperValue) or ./upperValue[not(@value)]">1</xsl:when>
        <xsl:when test="./upperValue[@value = '*']">unbounded</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="./upperValue/@value"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <xsl:template name="elementType">
    <xsl:choose>
      <xsl:when test="./type[@href]">
        <xsl:variable name="ext" select="xmi2xsd:resolveExternalType(./type)"/>
        <xsl:variable name="t" select="map:get($ext, 'type')"/>
        <xsl:choose>
          <xsl:when test="not($t='tns:Any')">
            <xsl:attribute name="type" select="$t"/>
            <xsl:namespace name="{map:get($ext,'pfx')}" select="map:get($ext, 'tns')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="type"
              select="QName( 'http://www.w3.org/2001/XMLSchema' , 'xs:anyType' )"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="@type">
        <xsl:call-template name="injectType">
          <xsl:with-param name="type" select="xmi2xsd:resolveType(., @type)"/>
          <xsl:with-param name="typeAttr" select="'type'"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:attribute name="type">UNDEFINED</xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template name="simpleType">
    <xsl:element name="xs:simpleType">
      <xsl:attribute name="name" select="@name"/>
      <xsl:element name="xs:restriction">
        <xsl:attribute name="base">xs:string</xsl:attribute>
      </xsl:element>
    </xsl:element>
    <!--    <xs:simpleType name="UUID-random">-->
    <!--      <xs:restriction base="xs:string">-->
    <!--        <xs:length value="36" fixed="true" />-->
    <!--        <xs:pattern value="[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[8-9a-bA-B][0-9a-fA-F]{3}-[0-9a-fA-F]{12}" fixed="true" />-->
    <!--      </xs:restriction>-->
    <!--    </xs:simpleType>-->
  </xsl:template>

  <xsl:template name="enums">
    <xsl:element name="xs:simpleType">
      <xsl:attribute name="name" select="@name"/>
      <xsl:element name="xs:restriction">
        <xsl:attribute name="base">xs:string</xsl:attribute>
        <xsl:for-each select="./ownedLiteral">
          <xsl:element name="xs:enumeration">
            <xsl:attribute name="value" select="@name"/>
          </xsl:element>
        </xsl:for-each>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <!-- Handle package imports -->

  <xsl:template name="resolveImports">
    <xsl:param name="root"/>
    <xsl:variable name="namespaces" select="map:merge(xmi2xsd:loadImports($root))"/>

    <xsl:for-each select="map:keys($namespaces)">
      <xsl:namespace name="{concat('ns',position())}" select="."/>
    </xsl:for-each>

    <xsl:for-each select="map:keys($namespaces)">
      <xsl:call-template name="addImport">
        <xsl:with-param name="ns" select="."/>
        <xsl:with-param name="path" select="map:get($namespaces, .)"/>
      </xsl:call-template>
    </xsl:for-each>

  </xsl:template>

  <xsl:template name="addImport">
    <xsl:param name="ns" as="xs:string"/>
    <xsl:param name="path" as="xs:string"/>
    <xsl:element name="xs:import">
      <xsl:attribute name="namespace">
        <xsl:value-of select="$ns"/>
      </xsl:attribute>
      <xsl:if test="$path and $path != ''">
        <xsl:attribute name="schemaLocation">
          <xsl:value-of select="$path"/>
        </xsl:attribute>
      </xsl:if>
    </xsl:element>
  </xsl:template>


  <xsl:function name="xmi2xsd:loadImports" as="map(xs:string,text())*">
    <xsl:param name="root" as="node()"/>
    <xsl:for-each select="$root/packageImport">
      <xsl:variable name="idx" select="xs:string(position())" as="xs:string"/>
      <xsl:choose>

        <xsl:when test="./importedPackage/@href">
          <xsl:variable name="externals" select="xmi2xsd:resolveExternalImports(importedPackage)"/>
          <xsl:variable name="rootPath" select="xmi2xsd:packageToSchemaLocation($root, ())"/>

          <xsl:for-each select="$externals">
            <xsl:variable name="in_pfx" select="concat('ns', $idx, '_', position())"
              as="xs:string"/>

            <xsl:variable name="external" select="."/>
            <xsl:map-entry key="xs:string($external('tns'))"
              select="xmi2xsd:makeRelative($external('schemaLocation'), $rootPath)"/>
          </xsl:for-each>
        </xsl:when>

        <xsl:when test="@importedPackage">
          <xsl:variable name="importedPack"
            select="//packagedElement[@xmi:id = current()/@importedPackage]"/>
          <xsl:variable name="ns" select="xmi2xsd:namespaceURI($importedPack)"/>
          <xsl:variable name="pfx" select="concat('ns', $idx)" as="xs:string"/>

          <xsl:map-entry key="xs:string($ns)"
            select="xmi2xsd:packageToSchemaLocation($importedPack, $root)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>


</xsl:stylesheet>
