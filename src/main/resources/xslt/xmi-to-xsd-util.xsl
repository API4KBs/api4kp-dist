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
  xmlns:uml="http://www.eclipse.org/uml2/5.0.0/UML"
  xmlns:cpt="https://omg.org/spec/API4KP/20200801/umlprofile/cpt"
  xmlns:xmi2xsd="http://www.mayo.edu/kmdp/xmi2xsd"
  xsi:schemaLocation="http://www.w3.org/1999/XSL/Transform
    https://www.w3.org/TR/xslt-30/schema-for-xslt30.xsd"
  xmi:version="2.5" version="3.0">


  <xsl:function name="xmi2xsd:contentGroupName" as="xs:QName">
    <xsl:param name="namedElement" as="node()"/>
    <xsl:sequence select="xmi2xsd:contentGroupName($namedElement,())"/>
  </xsl:function>
  <xsl:function name="xmi2xsd:contentGroupName" as="xs:QName">
    <xsl:param name="namedElement" as="node()"/>
    <xsl:param name="prefix" as="xs:string?"/>
    <xsl:sequence select="xmi2xsd:qualifiedName($prefix,$namedElement,'.content')"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:attrGroupName" as="xs:QName">
    <xsl:param name="namedElement" as="node()"/>
    <xsl:sequence select="xmi2xsd:attrGroupName($namedElement,())"/>
  </xsl:function>
  <xsl:function name="xmi2xsd:attrGroupName" as="xs:QName">
    <xsl:param name="namedElement" as="node()"/>
    <xsl:param name="prefix" as="xs:string?"/>
    <xsl:sequence select="xmi2xsd:qualifiedName($prefix,$namedElement,'.attrs')"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:qualifiedName" as="xs:QName">
    <xsl:param name="prefix" as="xs:string?"/>
    <xsl:param name="namedElement" as="node()"/>
    <xsl:param name="suffix" as="xs:string?"/>
    <xsl:sequence select="QName(xmi2xsd:namespaceURI(xmi2xsd:ownerPackage($namedElement)),
                          concat(if ($prefix) then concat($prefix,':') else '',$namedElement/@name,$suffix))"/>
  </xsl:function>


  <xsl:function name="xmi2xsd:package2namespace">
    <xsl:param name="packageNode" as="node()"/>
    <xsl:value-of>
      <xsl:choose>
        <xsl:when test="$packageNode/@URI">
          <xsl:value-of select="$packageNode/@URI"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of
            select="xmi2xsd:fullyQualifiedOwnerPackageName($packageNode, false())"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:value-of>
  </xsl:function>

  <xsl:function name="xmi2xsd:namespaceURI">
    <xsl:param name="node" as="node()"/>
    <xsl:value-of>
      <xsl:choose>
        <xsl:when test="$node/@URI">
          <xsl:value-of select="$node/@URI"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="parentNamespace">
            <xsl:if test="$node/..[@xmi:type = 'uml:Package'] or $node/../@URI">
              <xsl:value-of select="xmi2xsd:namespaceURI($node/..)"/>
            </xsl:if>
          </xsl:variable>
          <xsl:value-of select="concat($parentNamespace, '/', $node/@name)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:value-of>
  </xsl:function>


  <xsl:function name="xmi2xsd:getInternalTypeInfo" as="map(xs:string,item()*)">
    <xsl:param name="typeId" as="xs:string"/>
    <xsl:param name="type" as="node()"/>
    <xsl:variable name="conceptUri" select="xmi2xsd:getConcept($type)"/>
    <xsl:variable name="qName" select="xmi2xsd:resolveQualifiedInternalType($type, $typeId)"/>
    <xsl:map>
      <xsl:map-entry key="'childrenIds'" select="xmi2xsd:getDescendantIds($type)"/>
      <xsl:map-entry key="'conceptUri'" select="$conceptUri"/>
      <xsl:map-entry key="'name'" select="$type/@name"/>
      <xsl:map-entry key="'semName'"
        select="if (exists($conceptUri)) then $conceptUri else $type/@name"/>
      <xsl:map-entry key="'type'" select="$qName"/>
      <xsl:map-entry key="'fqName'" select="xmi2xsd:qNameToPackageName($qName)"/>
    </xsl:map>
  </xsl:function>

  <xsl:function name="xmi2xsd:qNameToPackageName" as="xs:string">
    <xsl:param name="qName" as="xs:QName"/>
    <xsl:variable name="namespace" select="replace( replace(namespace-uri-from-QName($qName),'https://',''), 'http://', '')"/>
    <xsl:variable name="packFragments"
      select="xmi2xsd:toPackageNameFragment(tokenize($namespace,'/'))"/>
    <xsl:value-of
      select="concat( string-join( $packFragments, '.') ,'.', local-name-from-QName($qName) )"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:toPackageNameFragment" as="xs:string*">
    <xsl:param name="x" as="xs:string*"/>
    <xsl:for-each select="$x">
      <xsl:variable name="y" select="lower-case(.)"/>
      <xsl:choose>
        <xsl:when test="matches($y,'^\d.*')">
          <xsl:sequence select="concat('_',replace($y,'\.','_'))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="reverse(tokenize( replace($y,'^(www\.)','') ,'\.'))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="xmi2xsd:getConcept" as="xs:anyURI?">
    <xsl:param name="entity" as="node()"/>
    <xsl:variable name="id" select="$entity/@xmi:id"/>
    <xsl:sequence
      select="root($entity)//cpt:Conceptual[@base_Class = $id or @base_Property = $id or @base_Association = $id]/@concept"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:getDescendantIds" as="xs:string*">
    <!-- TODO does not work across model documents -->
    <xsl:param name="parent" as="node()"/>
    <xsl:variable name="parentId" select="$parent/@xmi:id"/>

    <xsl:for-each
      select="root($parent)//generalization[ @general=$parentId ]">
      <xsl:variable name="child" select="parent::node()"/>
      <xsl:variable name="childId" select="$child/@xmi:id"/>
      <xsl:sequence select="xs:string($childId), xmi2xsd:getDescendantIds($child)"/>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="xmi2xsd:ownerPackage" as="node()?">
    <xsl:param name="namedElement" as="node()"/>
    <xsl:sequence select="$namedElement/ancestor::packagedElement[@xmi:type = 'uml:Package'][1]"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:fullyQualifiedOwnerPackageName">
    <xsl:param name="namedElement" as="node()"/>
    <xsl:param name="withModel" as="xs:boolean"/>
    <xsl:variable name="parentNS">
      <xsl:for-each
        select="$namedElement/ancestor::packagedElement[@xmi:type = 'uml:Package']">
        <xsl:value-of select="concat(@name, '.')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="scope">
      <xsl:choose>
        <xsl:when test="$withModel">
          <xsl:value-of select="concat(root($namedElement)//uml:Model/@name, '.')"/>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat($scope, $parentNS, $namedElement/@name)"/>
  </xsl:function>


  <xsl:function name="xmi2xsd:nsToFolderPath">
    <xsl:param name="ns" as="xs:string"/>
    <xsl:value-of select="replace($ns, '\.', '/')"/>
  </xsl:function>


  <xsl:function name="xmi2xsd:packageToSchemaLocation">
    <xsl:param name="package" as="node()"/>
    <xsl:param name="relativeTo" as="node()?"/>
    <xsl:value-of select="xmi2xsd:packageToSchemaLocation($package,$relativeTo,'.xsd')"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:packageToSchemaLocation">
    <xsl:param name="package" as="node()"/>
    <xsl:param name="relativeTo" as="node()?"/>
    <xsl:param name="ext" as="xs:string"/>
    <xsl:value-of
      select="xmi2xsd:packageToSchemaLocation($package,$relativeTo,$package/@name,$ext)"/>
  </xsl:function>

  <xsl:function name="xmi2xsd:packageToSchemaLocation">
    <xsl:param name="package" as="node()"/>
    <xsl:param name="relativeTo" as="node()?"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="ext" as="xs:string"/>

    <xsl:variable name="fqpn" select="xmi2xsd:fullyQualifiedOwnerPackageName($package, true())"/>
    <xsl:variable name="path" select="xmi2xsd:nsToFolderPath($fqpn)"/>
    <xsl:variable name="location" select="concat($path, '/', $name, $ext)"/>

    <xsl:choose>
      <xsl:when test="$relativeTo">
        <xsl:variable name="rel" select="xmi2xsd:packageToSchemaLocation($relativeTo, ())"/>
        <xsl:value-of select="xmi2xsd:makeRelative($location, $rel)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$location"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="xmi2xsd:makeRelative">
    <xsl:param name="location" as="xs:string"/>
    <xsl:param name="origin" as="xs:string"/>

    <xsl:choose>
      <xsl:when test="$location != ''">

        <xsl:variable name="tgt" select="tokenize($location, '/')"/>
        <xsl:variable name="src" select="tokenize($origin, '/')"/>

        <xsl:variable name="base" select="tokenize( xmi2xsd:commonRoot($src, $tgt), ' ' )"/>

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

  <xsl:function name="xmi2xsd:commonRoot">
    <xsl:param name="arg1" as="xs:string*"/>
    <xsl:param name="arg2" as="xs:string*"/>
    <xsl:choose>
      <xsl:when test="$arg1[1] = $arg2[1]">
        <xsl:value-of
          select="
                        insert-before(
                        xmi2xsd:commonRoot(subsequence($arg1, 2), subsequence($arg2, 2)),
                        0,
                        $arg1[1])"
        />
      </xsl:when>
    </xsl:choose>
  </xsl:function>


  <xsl:function name="xmi2xsd:resolvePrimitive" as="xs:QName">
    <xsl:param name="primitiveType" as="xs:string"/>
    <xsl:variable name="simpleType">
      <xsl:choose>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/UMLPrimitiveTypes.library.uml#String'">xs:string</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/UMLPrimitiveTypes.library.uml#Boolean'">xs:boolean</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/UMLPrimitiveTypes.library.uml#Integer'">xs:int</xsl:when>
        <xsl:when
          test="$primitiveType = 'uml:Enumeration'">xs:string</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/XMLPrimitiveTypes.library.uml#Duration'">xs:duration</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/XMLPrimitiveTypes.library.uml#Base64Binary'">xs:base64Binary</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/XMLPrimitiveTypes.library.uml#Decimal'">xs:decimal</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/XMLPrimitiveTypes.library.uml#DateTime'">xs:dateTime</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/XMLPrimitiveTypes.library.uml#Date'">xs:date</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/XMLPrimitiveTypes.library.uml#AnySimpleType'">xs:anySimpleType</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/XMLPrimitiveTypes.library.uml#String'">xs:string</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/XMLPrimitiveTypes.library.uml#AnyURI'">xs:anyURI</xsl:when>
        <xsl:when
          test="$primitiveType = 'pathmap://UML_LIBRARIES/XMLPrimitiveTypes.library.uml#QName'">xs:QName</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring($primitiveType, index-of($primitiveType,'#'))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="QName('http://www.w3.org/2001/XMLSchema',$simpleType)"/>
  </xsl:function>


  <xsl:function name="xmi2xsd:resolveType" as="xs:QName">
    <xsl:param name="typedElement" as="node()"/>
    <xsl:param name="typeId" as="xs:string"/>

    <xsl:choose>

      <xsl:when test="xmi2xsd:isTypeLocal($typedElement, $typeId)">
        <xsl:variable name="resolvedType"
          select="xmi2xsd:resolveQualifiedInternalType($typedElement, $typeId)"/>
        <!-- TODO FIXME The use of a class called 'Any' (or Object or anything) as a conventional placeHolder has to be replaced by something more proper -->
        <!-- E.g. a class Called Any in the XSD package -->
        <xsl:choose>
          <xsl:when test="local-name-from-QName($resolvedType)='Any'">
            <xsl:sequence select="QName( 'http://www.w3.org/2001/XMLSchema' , 'xs:anyType' )"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$resolvedType"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="root($typedElement)//ownedParameter[@parameteredElement = $typeId]">
        <xsl:variable name="paramType">
          <xsl:value-of
            select="root($typedElement)//ownedParameter[@parameteredElement = $typeId]/ownedParameteredElement/@xmi:type"
          />
        </xsl:variable>
        <!-- TODO Params can be more general, call should recur -->
        <xsl:sequence select="xmi2xsd:resolvePrimitive($paramType)"/>
      </xsl:when>

      <xsl:otherwise>
        <xsl:sequence select="xs:QName($typeId)"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:function>

  <xsl:function name="xmi2xsd:isTypeLocal" as="xs:boolean">
    <xsl:param name="typedElement" as="node()"/>
    <xsl:param name="typeId" as="xs:string"/>
    <xsl:value-of
      select="
                exists( root($typedElement)//packagedElement[
                (@xmi:type = 'uml:DataType' or @xmi:type = 'uml:Class' or @xmi:type = 'uml:Enumeration')
                and @xmi:id = $typeId] )"
    />
  </xsl:function>


  <xsl:function name="xmi2xsd:resolveQualifiedInternalType" as="xs:QName">
    <xsl:param name="context" as="node()?"/>
    <xsl:param name="typeId" as="xs:string"/>

    <xsl:variable name="type" select="root($context)//packagedElement[@xmi:id = $typeId]"/>
    <xsl:variable name="typeNs" as="xs:string?"
      select="$type/ancestor::packagedElement[@xmi:type = 'uml:Package'][1]/@URI"/>
    <xsl:variable name="typeName" as="xs:string" select="$type/@name"/>

    <xsl:sequence select="QName($typeNs, $typeName)"/>
  </xsl:function>


  <xsl:function name="xmi2xsd:toFolderURI">
    <xsl:param name="folderName" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="contains($folderName,':\')">
        <xsl:value-of select="concat('file:/',replace($folderName,'\\','/'))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$folderName"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="xmi2xsd:shouldIncludePackage" as="xs:boolean">
    <xsl:param name="package" as="node()"/>
    <xsl:param name="includedPackages" as="xs:string?"/>
    <xsl:sequence
      select="empty($includedPackages) 
              or $includedPackages = '*' 
              or $package/@name = tokenize($includedPackages,',')"/>
  </xsl:function>


</xsl:stylesheet>
