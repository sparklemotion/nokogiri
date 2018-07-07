/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2012:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com]
 * * {Sergio Arbeo}[http://www.serabe.com]
 * * {Patrick Mahoney}[http://polycrystal.org]
 * * {Yoko Harada}[http://yokolet.blogspot.com]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getCachedNodeOrCreate;
import static nokogiri.internals.NokogiriHelpers.getLocalNameForNamespace;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;
import nokogiri.internals.SaveContextVisitor;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::Namespace
 * 
 * @author serabe
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name="Nokogiri::XML::Namespace")
public class XmlNamespace extends RubyObject {
    private Attr attr;
    private transient IRubyObject prefix;
    private transient IRubyObject href;
    private String prefixString;
    private String hrefString;

    public XmlNamespace(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    XmlNamespace(Ruby runtime, Attr attr, String prefix, String href, IRubyObject document) {
        super(runtime, getNokogiriClass(runtime, "Nokogiri::XML::Namespace"));

        init(attr, stringOrNil(runtime, prefix), stringOrNil(runtime, href), prefix, href, document);
    }

    private XmlNamespace(Ruby runtime, Attr attr, IRubyObject prefix, String prefixString,
                         IRubyObject href, String hrefString, IRubyObject document) {
        super(runtime, getNokogiriClass(runtime, "Nokogiri::XML::Namespace"));

        init(attr, prefix, href, prefixString, hrefString, document);
    }

    public Node getNode() {
        return attr;
    }
    
    public String getPrefix() {
        return prefixString;
    }
    
    public String getHref() {
        return hrefString;
    }
    
    void deleteHref() {
        hrefString = "http://www.w3.org/XML/1998/namespace";
        href = null;
        attr.getOwnerElement().removeAttributeNode(attr);
    }
    
    private void init(Attr attr, IRubyObject prefix, IRubyObject href,
                      String prefixString, String hrefString, IRubyObject document) {
        this.attr = attr;
        this.prefix = prefix;
        this.href = href;
        this.prefixString = prefixString;
        this.hrefString = hrefString;
        setInstanceVariable("@document", document);
    }
    
    public static XmlNamespace createFromAttr(Ruby runtime, Attr attr) {
        String prefixValue = getLocalNameForNamespace(attr.getName());
        IRubyObject prefix_value;
        if (prefixValue == null) {
            prefix_value = runtime.getNil(); prefixValue = "";
        } else {
            prefix_value = RubyString.newString(runtime, prefixValue);
        }
        String hrefValue = attr.getValue();
        IRubyObject href_value = RubyString.newString(runtime, hrefValue);
        // check namespace cache
        XmlDocument xmlDocument = (XmlDocument)getCachedNodeOrCreate(runtime, attr.getOwnerDocument());
        xmlDocument.initializeNamespaceCacheIfNecessary();
        XmlNamespace xmlNamespace = xmlDocument.getNamespaceCache().get(prefixValue, hrefValue);
        if (xmlNamespace != null) return xmlNamespace;
        
        // creating XmlNamespace instance
        XmlNamespace namespace = new XmlNamespace(runtime, attr, prefix_value, prefixValue, href_value, hrefValue, xmlDocument);
        
        // updateing namespace cache
        xmlDocument.getNamespaceCache().put(namespace, attr.getOwnerElement());
        return namespace;
    }
    
    public static XmlNamespace createFromPrefixAndHref(Node owner, IRubyObject prefix, IRubyObject href) {
        String prefixValue = prefix.isNil() ? "" : prefix.toString();
        String hrefValue = href.toString();
        Ruby runtime = prefix.getRuntime();
        Document document = owner.getOwnerDocument();
        // check namespace cache
        XmlDocument xmlDocument = (XmlDocument)getCachedNodeOrCreate(runtime, document);
        xmlDocument.initializeNamespaceCacheIfNecessary();
        XmlNamespace xmlNamespace = xmlDocument.getNamespaceCache().get(prefixValue, hrefValue);
        if (xmlNamespace != null) return xmlNamespace;

        // creating XmlNamespace instance
        String attrName = "xmlns";
        if (!prefixValue.isEmpty()) {
            attrName = attrName + ':' + prefixValue;
        }
        Attr attrNode = document.createAttribute(attrName);
        attrNode.setNodeValue(hrefValue);

        XmlNamespace namespace = new XmlNamespace(runtime, attrNode, prefix, prefixValue, href, hrefValue, xmlDocument);
        
        // updating namespace cache
        xmlDocument.getNamespaceCache().put(namespace, owner);
        return namespace;
    }
    
    // owner should be an Attr node
    public static XmlNamespace createDefaultNamespace(Ruby runtime, Node owner) {
        String prefixValue = owner.getPrefix();
        String hrefValue = owner.getNamespaceURI();
        Document document = owner.getOwnerDocument();
        // check namespace cache
        XmlDocument xmlDocument = (XmlDocument)getCachedNodeOrCreate(runtime, document);
        XmlNamespace xmlNamespace = xmlDocument.getNamespaceCache().get(prefixValue, hrefValue);
        if (xmlNamespace != null) return xmlNamespace;

        // creating XmlNamespace instance
        XmlNamespace namespace = new XmlNamespace(runtime, (Attr) owner, prefixValue, hrefValue, xmlDocument);
        
        // updating namespace cache
        xmlDocument.getNamespaceCache().put(namespace, owner);
        return namespace;
    }
    
    /**
     * Create and return a copy of this object.
     *
     * @return a clone of this object
     */
    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }

    public boolean isEmpty() {
        return (prefix == null || prefix.isNil()) && (href == null || href.isNil());
    }

    @JRubyMethod
    public IRubyObject href(ThreadContext context) {
        if (href == null) {
            return href = context.runtime.newString(hrefString);
        }
        return href;
    }

    @JRubyMethod
    public IRubyObject prefix(ThreadContext context) {
        if (prefix == null) {
            return prefix = context.runtime.newString(prefixString);
        }
        return prefix;
    }
    
    public void accept(ThreadContext context, SaveContextVisitor visitor) {
        String string = " " + prefixString + "=\"" + hrefString + "\"";
        visitor.enter(string);
        visitor.leave(string);
        // is below better?
        //visitor.enter(attr);
        //visitor.leave(attr);
    }
}
