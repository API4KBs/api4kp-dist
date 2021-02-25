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
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
  xmlns:res="https://omg.org/spec/API4KP/20210201/umlprofile/res"
  xmlns:uml="http://www.eclipse.org/uml2/5.0.0/UML"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:xmi2xsd="http://www.mayo.edu/kmdp/xmi2xsd"
  xmlns:vs="https://omg.org/spec/API4KP/20210201/umlprofile/vs"
  xmlns:fn="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="xs" version="3.0">
  <!-- TODO: Check the vs: namespace -->

  <xsl:import href="xmi-to-xsd-util.xsl"/>

  <xsl:template match="text() | @*"/>


  <xsl:function name="xmi2xsd:resolveExternalType" as="map(xs:string,text())">
    <xsl:param name="hrefElement" as="node()"/>
    <xsl:variable name="external"
      select="xmi2xsd:loadExternalEntity($hrefElement/@href, document-uri(root($hrefElement)), QName('', 'entityType'))"/>
    <xsl:map>
      <xsl:map-entry key="'type'">
        <xsl:value-of select="$external//@type"/>
      </xsl:map-entry>
      <xsl:map-entry key="'tns'">
        <xsl:value-of select="$external//@tns"/>
      </xsl:map-entry>
      <xsl:map-entry key="'pfx'">tns</xsl:map-entry>
    </xsl:map>
  </xsl:function>

  <xsl:function name="xmi2xsd:resolveExternalProfile" as="xs:QName">
    <xsl:param name="hrefElement" as="node()"/>
    <xsl:variable name="external"
      select="xmi2xsd:loadExternalEntity($hrefElement/@href, document-uri(root($hrefElement)), QName('', 'profile'))"/>
    <xsl:sequence
      select="QName($external//@tns,
            concat($external//@pfx,':',$external//@name))"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:resolveExternalImports" as="map(xs:string,text())*">
    <xsl:param name="hrefElement" as="node()"/>
    <xsl:variable name="externalNamespaces"
      select="xmi2xsd:transformExternal($hrefElement/@href, document-uri(root($hrefElement)), QName('', 'package'))"/>

    <xsl:for-each
      select="$externalNamespaces//child[@sourceId=substring-after($hrefElement/@href,'#')]">
      <xsl:map>
        <xsl:map-entry key="'tns'">
          <xsl:value-of select="@tns"/>
        </xsl:map-entry>
        <xsl:map-entry key="'schemaLocation'">
          <xsl:value-of select="@schemaLocation"/>
        </xsl:map-entry>
      </xsl:map>
    </xsl:for-each>

  </xsl:function>

  <!--<xsl:function name="xmi2xsd:resolveExternalParametricProperty" as="map(xs:string,text())">
      <xsl:param name="hrefElement" as="node()"/>
      <xsl:variable name="external"
          select="xmi2xsd:loadExternalEntity($hrefElement/@href, document-uri(root($hrefElement)), QName('', 'parametric'))"/>
      <xsl:map>
          <xsl:map-entry key="'name'">
              <xsl:value-of select="$external//@name"/>
          </xsl:map-entry>
          <xsl:map-entry key="'min'">
              <xsl:value-of select="$external//@min"/>
          </xsl:map-entry>
      </xsl:map>
  </xsl:function>-->


  <!-- Create a temporary node to migrate entity type information -->
  <xsl:template name="entityType">
    <xsl:element name="root">
      <xsl:for-each select="//packagedElement">
        <xsl:variable name="type" select="."/>

        <xsl:variable name="package"
          select="xmi2xsd:ownerPackage($type)"/>
        <xsl:variable name="nsURI">
          <xsl:choose>
            <xsl:when test="//vs:ValueSet[@base_Enumeration = current()/@xmi:id]">
              <xsl:value-of
                select="//vs:ValueSet[@base_Enumeration = current()/@xmi:id]/@uri"/>
            </xsl:when>
            <xsl:when test="$package">
              <xsl:value-of select="xmi2xsd:namespaceURI($package)"/>
            </xsl:when>
            <xsl:otherwise>ERROR:: Unable to Resolve Namespace</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:element name="child">
          <xsl:attribute name="sourceId" select="$type/@xmi:id"/>
          <xsl:attribute name="tns">
            <xsl:value-of select="$nsURI"/>
          </xsl:attribute>
          <xsl:attribute name="type">
            <xsl:value-of select="concat('tns:', $type/@name)"/>
          </xsl:attribute>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>

  <!-- Create a temporary node to migrate profile information -->
  <xsl:template name="profile">
    <xsl:element name="root">
      <xsl:for-each select="//packagedElement[@xmi:type='uml:Profile']//contents">
        <xsl:element name="child">
          <xsl:attribute name="sourceId" select="./@xmi:id"/>
          <xsl:attribute name="tns">
            <xsl:value-of select="./@nsURI"/>
          </xsl:attribute>
          <xsl:attribute name="name">
            <xsl:value-of select="./@name"/>
          </xsl:attribute>
          <xsl:attribute name="pfx">
            <xsl:value-of select="./@nsPrefix"/>
          </xsl:attribute>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>

  <!-- Create a temporary node to migrate package information -->
  <xsl:template name="package">
    <xsl:element name="root">
      <xsl:for-each select="//packagedElement">
        <xsl:choose>
          <xsl:when test="//vs:ValueSet[@base_Enumeration = current()/@xmi:id]">
            <xsl:element name="child">
              <xsl:attribute name="sourceId" select="../@xmi:id"/>
              <xsl:attribute name="tns"
                select="//vs:ValueSet[@base_Enumeration = current()/@xmi:id]/@uri"/>
              <xsl:attribute name="schemaLocation" select="''"/>
            </xsl:element>
          </xsl:when>
          <xsl:when test=".[@xmi:type = 'uml:Package']">
            <!-- Exclude 'terminology container' packages -->
            <!-- TODO when more profiles are defined, check that
                the actual profile is the ValueSet one -->
            <xsl:if test="not(xmi2xsd:isTerminologyPackage(.))">
              <xsl:variable name="pack" select="." as="node()"/>
              <xsl:variable name="packageNamespaceURI"
                select="xmi2xsd:namespaceURI($pack)" as="xs:anyURI?"/>

              <xsl:variable name="schemaPath"
                select="xmi2xsd:packageToSchemaLocation($pack, ())"/>

              <xsl:element name="child">
                <xsl:attribute name="sourceId" select="$pack/@xmi:id"/>
                <xsl:attribute name="tns" select="$packageNamespaceURI"/>
                <xsl:if test="$schemaPath != ''">
                  <xsl:attribute name="schemaLocation" select="$schemaPath"/>
                </xsl:if>
              </xsl:element>
            </xsl:if>
          </xsl:when>
        </xsl:choose>

      </xsl:for-each>
    </xsl:element>
  </xsl:template>


  <!-- Create a temporary node to migrate package information -->
  <!-- TODO Can likely delete -->
  <xsl:template name="parametric">
    <xsl:element name="root">
      <xsl:for-each select="//ownedParameter">
        <xsl:variable name="param" select="."/>
        <xsl:variable name="parametricElement" select="$param/ownedParameteredElement"/>
        <xsl:variable name="attr"
          select="$param/../../ownedAttribute[@type = $parametricElement/@xmi:id]"/>

        <xsl:element name="child">
          <xsl:attribute name="sourceId" select="$param/@xmi:id"/>
          <xsl:attribute name="name" select="$attr/@name"/>
          <xsl:attribute name="min" select="$attr/lowerValue/@value"/>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>


  <xsl:function name="xmi2xsd:loadExternalEntity">
    <xsl:param name="ref" as="xs:anyURI"/>
    <xsl:param name="baseURI" as="xs:anyURI"/>
    <xsl:param name="loader" as="xs:QName"/>

    <xsl:variable name="refID" select="substring-after($ref, '#')"/>

    <xsl:variable name="out" select="xmi2xsd:transformExternal($ref, $baseURI, $loader)"/>
    <xsl:variable name="o2" select="$out//child[@sourceId = $refID]"/>
    <xsl:copy-of select="$o2"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:transformExternal" as="node()">
    <xsl:param name="ref" as="xs:anyURI"/>
    <xsl:param name="baseURI" as="xs:anyURI"/>
    <xsl:param name="loader" as="xs:QName"/>
    <xsl:variable name="sourceDoc"
      select="
                concat(
                string-join(tokenize($baseURI, '/')[position() != last()], '/'),
                '/',
                substring-before($ref, '#'))"/>
    <xsl:variable name="opts"
      select="
                map {
                    'stylesheet-location': 'hrefResolver.xsl',
                    'source-node': fn:doc($sourceDoc),
                    'initial-template': $loader
                }"/>
    <!-- 'template-params'       : map{ QName('','anchorId') : $refID } -->
    <xsl:variable name="out" select="fn:transform($opts)?output" as="node()"/>
    <xsl:copy-of select="$out"/>
  </xsl:function>


  <xsl:function name="xmi2xsd:getProfiles" as="xs:QName*">
    <xsl:param name="pack" as="node()"/>
    <xsl:choose>
      <xsl:when test="$pack//profileApplication">
        <xsl:for-each select="$pack//profileApplication">
          <xsl:variable name="refs" select="current()//references"/>
          <xsl:variable name="prof" select="xmi2xsd:resolveExternalProfile($refs)"/>
          <xsl:sequence select="$prof"/>
        </xsl:for-each>
      </xsl:when>
    </xsl:choose>
  </xsl:function>


  <xsl:function name="xmi2xsd:isTerminologyPackage" as="xs:boolean">
    <xsl:param name="pack" as="node()"/>
    <xsl:sequence
      select="QName('https://omg.org/spec/API4KP/20210201/umlprofile/vs','ConceptAware') = xmi2xsd:getProfiles($pack)"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:isResourcePackage" as="xs:boolean">
    <xsl:param name="pack" as="node()"/>
    <xsl:sequence
      select="QName('https://omg.org/spec/API4KP/20210201/umlprofile/res','Resource') = xmi2xsd:getProfiles($pack)"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:isRestResource" as="xs:boolean">
    <xsl:param name="klass" as="node()"/>
    <xsl:param name="pack" as="node()"/>
    <xsl:variable name="doc" select="root($pack)"/>
    <xsl:variable name="id" select="$klass/@xmi:id"/>
    <xsl:variable name="rest" select="xmi2xsd:isResourcePackage($pack)" as="xs:boolean"/>

    <xsl:variable name="marker" select="exists($doc//res:Resource[@base_Class = $id])"/>

    <xsl:sequence select="$rest and $marker"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:isRestResource" as="xs:boolean">
    <xsl:param name="klass" as="node()"/>
    <xsl:variable name="doc" select="root($klass)"/>
    <xsl:variable name="id" select="$klass/@xmi:id"/>
    <xsl:sequence select="exists($doc//res:Resource[@base_Class = $id])"/>
  </xsl:function>


  <xsl:function name="xmi2xsd:getResourceEntityIDAttribute" as="xs:string?">
    <xsl:param name="klass" as="node()"/>
    <xsl:variable name="id" select="$klass/@xmi:id"/>
    <xsl:variable name="doc" select="root($klass)"/>
    <xsl:sequence select="$doc//res:Resource[@base_Class = $id]/@identifierAttribute"/>
  </xsl:function>

</xsl:stylesheet>
