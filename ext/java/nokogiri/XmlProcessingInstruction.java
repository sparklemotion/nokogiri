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

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::ProcessingInstruction
 * 
 * @author sergio
 */
@JRubyClass(name="Nokogiri::XML::ProcessingInstruction", parent="Nokogiri::XML::Node")
public class XmlProcessingInstruction extends XmlNode {

    public XmlProcessingInstruction(Ruby ruby, RubyClass klass, Node node) {
        super(ruby, klass, node);
    }

    @JRubyMethod(name="new", meta=true, rest=true, required=3)
    public static IRubyObject rbNew(ThreadContext context,
                                    IRubyObject klass,
                                    IRubyObject[] args) {

        IRubyObject doc = args[0];
        IRubyObject target = args[1];
        IRubyObject data = args[2];

        Document document = ((XmlNode) doc).getOwnerDocument();
        Node node =
            document.createProcessingInstruction(rubyStringToString(target),
                                                 rubyStringToString(data));
        XmlProcessingInstruction self =
            new XmlProcessingInstruction(context.getRuntime(),
                                         (RubyClass) klass,
                                         node);

        RuntimeHelpers.invoke(context, self, "initialize", args);

        // TODO: if_block_given.

        return self;
    }

    @Override
    public boolean isProcessingInstruction() { return true; }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        ctx.append("<?");
        ctx.append(node_name(context).convertToString().asJavaString());
        IRubyObject content = content(context);
        if(!content.isNil()) {
            if (ctx.asHtml()) ctx.append(" ");
            ctx.append(content.convertToString().asJavaString());
        }
        if (ctx.asHtml())
            ctx.append(">");
        else
            ctx.append("?>");
    }

}
