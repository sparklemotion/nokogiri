/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2011:
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

import static nokogiri.internals.NokogiriHelpers.getLocalNameForNamespace;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::Namespace
 * 
 * @author serabe
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name="Nokogiri::XML::Namespace")
public class XmlNamespace extends RubyObject {

    private IRubyObject prefix;
    private IRubyObject href;

    public XmlNamespace(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }

    public XmlNamespace(Ruby ruby, String prefix, String href) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Namespace"), prefix, href);
    }

    public XmlNamespace(Ruby ruby, RubyClass klazz, String prefix, String href) {
        super(ruby, klazz);
        this.prefix = (prefix == null) ? ruby.getNil() : RubyString.newString(ruby, prefix);
        this.href = (href == null) ? ruby.getNil() : RubyString.newString(ruby, href);
    }

    public XmlNamespace(Ruby ruby, IRubyObject prefix, IRubyObject href) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Namespace"), prefix, href);
    }

    public XmlNamespace(Ruby ruby, RubyClass klazz, IRubyObject prefix, IRubyObject href) {
        super(ruby, klazz);
        this.prefix = prefix;
        this.href = href;
    }
    
    public void setDefinition(Ruby runtime, String prefix, String href) {
        this.prefix = (prefix == null) ? runtime.getNil() : RubyString.newString(runtime, prefix);
        this.href = (href == null) ? runtime.getNil() : RubyString.newString(runtime, href);
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

    public static XmlNamespace fromNode(Ruby ruby, Node node) {
        String localName = getLocalNameForNamespace(node.getNodeName());
        XmlNamespace namespace = (XmlNamespace) NokogiriService.XML_NAMESPACE_ALLOCATOR.allocate(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Namespace"));
        namespace.setDefinition(ruby, localName, node.getNodeValue());
        return namespace;
    }

    public boolean isEmpty() {
        return this.prefix.isNil() && this.href.isNil();
    }

    public void setDocument(IRubyObject doc) {
        this.setInstanceVariable("@document", doc);
    }

    @JRubyMethod
    public IRubyObject href(ThreadContext context) {
        return this.href;
    }

    @JRubyMethod
    public IRubyObject prefix(ThreadContext context) {
        return this.prefix;
    }
    
    public void saveContent(ThreadContext context, SaveContext ctx) {
        ctx.append(" " + prefix + "=\"" + href + "\"");
    }
}
