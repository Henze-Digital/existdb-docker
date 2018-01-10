<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:exist="http://exist.sourceforge.net/NS/exist"
    xmlns:log4j="http://jakarta.apache.org/log4j/"
    xmlns:webapp="http://xmlns.jcp.org/xml/ns/javaee"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <!--
        script for modifying eXist-db conf files
        to the WeGA needs
    -->
    
    <xsl:param name="env"/>
    <xsl:param name="context_path"/>
    
    <!-- needed servlets -->
    <!-- wird das ResourceServlet wirklich benötigt? Ja, für Dashboard etc-->
    <!-- 'org.exist.xmlrpc.RpcServlet' und 'JMXServlet' werden für Produktiv-Einsatz nicht benötigt -->
    <xsl:variable name="production-servlets" as="xs:string+" select="(
        'ResourceServlet',
        'EXistServlet',
        'XQueryServlet',
        'XQueryURLRewrite'
        )"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- 
        +++++++++++++++++++++++++++++++++++++++++
        $exist.home$/conf.xml
        +++++++++++++++++++++++++++++++++++++++++
    -->
    <xsl:template match="@preserve-whitespace-mixed-content[parent::indexer]">
        <xsl:attribute name="preserve-whitespace-mixed-content" select="'yes'"/>
    </xsl:template>
    
    <xsl:template match="@caching[parent::transformer]">
        <xsl:attribute name="caching">
            <xsl:choose>
                <xsl:when test="$env eq 'production'">yes</xsl:when>
                <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@indent[parent::serializer]">
        <xsl:attribute name="indent" select="'no'"/>
    </xsl:template>
    
    <!-- 
        +++++++++++++++++++++++++++++++++++++++++
        $exist.home$/webapp/WEB-INF/controller-config.xml
        +++++++++++++++++++++++++++++++++++++++++
    -->
    <xsl:template match="exist:forward">
        <xsl:if test="$env ne 'production' or @servlet = $production-servlets">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="exist:root">
        <xsl:choose>
            <xsl:when test="@pattern = '/apps'">
                <root pattern="/apps" path="xmldb:exist:///db/apps" xmlns="http://exist.sourceforge.net/NS/exist"/>
            </xsl:when>
            <xsl:when test="@pattern = '.*'">
                <root pattern=".*" path="xmldb:exist:///db/apps/WeGA-WebApp" xmlns="http://exist.sourceforge.net/NS/exist"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!--
        +++++++++++++++++++++++++++++++++++++++++
        $exist.home$/tools/jetty/webapps/exist-webapp-context.xml
        +++++++++++++++++++++++++++++++++++++++++
    -->
    <xsl:template match="Set[@name='contextPath' and $context_path]">
        <xsl:copy>
            <xsl:attribute name="name" select="'contextPath'"/>
            <xsl:value-of select="$context_path"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- 
        +++++++++++++++++++++++++++++++++++++++++
        $exist.home$/webapp/WEB-INF/web.xml
        +++++++++++++++++++++++++++++++++++++++++
    -->
    <xsl:template match="webapp:servlet[not(webapp:servlet-name = $production-servlets or $env ne 'production')]"/>
    
    <xsl:template match="webapp:servlet-mapping[not(webapp:servlet-name = 'XQueryURLRewrite' or $env ne 'production')]"/>
    
    <xsl:template match="webapp:filter[$env eq 'production']"/>
    
    <xsl:template match="webapp:filter-mapping[$env eq 'production']"/>
    
    <xsl:template match="webapp:login-config[$env eq 'production']"/>
    
    <xsl:template match="webapp:context-param[$env eq 'production']"/>
    
    <xsl:template match="webapp:listener[$env eq 'production']"/>
    
    <xsl:template match="webapp:init-param[webapp:param-name = 'hidden' and $env eq 'production']">
        <!-- Deny direct access to the REST interface -->
        <xsl:copy>
            <xsl:element name="param-name" namespace="http://xmlns.jcp.org/xml/ns/javaee">
                <xsl:text>hidden</xsl:text>
            </xsl:element>
            <xsl:element name="param-value" namespace="http://xmlns.jcp.org/xml/ns/javaee">
                <xsl:text>true</xsl:text>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <!-- 
        +++++++++++++++++++++++++++++++++++++++++
        $exist.home$/log4j2.xml
        +++++++++++++++++++++++++++++++++++++++++
    -->
    
    <xsl:template match="Logger[@name='wega.webapp'][$env ne 'production']">
        <xsl:copy>
            <xsl:apply-templates select="@* except @level"/>
            <xsl:attribute name="level">trace</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>