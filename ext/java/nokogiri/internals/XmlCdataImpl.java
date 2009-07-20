/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class XmlCdataImpl extends XmlNodeImpl {

    public XmlCdataImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    public IRubyObject blank_p(ThreadContext context, XmlNode node) {
        return context.getRuntime().newBoolean(this.isBlankNode(context, node));
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 4; }

    @Override
    public IRubyObject getNullContent(ThreadContext context) {
        return context.getRuntime().getNil();
    }
}
