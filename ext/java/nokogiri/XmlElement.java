package nokogiri;

import static nokogiri.internals.NokogiriHelpers.namedNodeMapToRubyArray;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
@JRubyClass(name="Nokogiri::XML::Element", parent="Nokogiri::XML::Node")
public class XmlElement extends XmlNode {

    public XmlElement(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    public XmlElement(Ruby runtime, RubyClass klazz, Node element) {
        super(runtime, klazz, element);
    }
    
    @Override
    public void setNode(ThreadContext context, Node node) {
        this.node = node;
        if (node != null) {
            resetCache();
            if (node.getNodeType() != Node.DOCUMENT_NODE) {
                doc = document(context);
                setInstanceVariable("@document", doc);
                if (doc != null) {
                    RuntimeHelpers.invoke(context, doc, "decorate", this);
                }
            }
        }
    }

    @Override
    @JRubyMethod(name = {"add_namespace_definition", "add_namespace"})
    public IRubyObject add_namespace_definition(ThreadContext context,
                                                IRubyObject prefix,
                                                IRubyObject href) {
        Element element = (Element) node;

        final String uri = "http://www.w3.org/2000/xmlns/";
        String qName =
            prefix.isNil() ? "xmlns" : "xmlns:" + rubyStringToString(prefix);
        element.setAttributeNS(uri, qName, rubyStringToString(href));

        XmlNamespace ns = (XmlNamespace)
            super.add_namespace_definition(context, prefix, href);
        updateNodeNamespaceIfNecessary(context, ns);

        return ns;
    }

    @Override
    public boolean isElement() { return true; }

    @Override
    @JRubyMethod(visibility = Visibility.PRIVATE)
    public IRubyObject get(ThreadContext context, IRubyObject rbkey) {
        if (rbkey == null || rbkey.isNil()) context.getRuntime().getNil();
        String key = (String)rbkey.toJava(String.class);
        Element element = (Element) node;
        String value = element.getAttribute(key);
        if(!value.equals("")){
            return context.getRuntime().newString(value);
        }
        return context.getRuntime().getNil();
    }

    @Override
    public IRubyObject key_p(ThreadContext context, IRubyObject rbkey) {
        String key = rubyStringToString(rbkey);
        Element element = (Element) node;
        return context.getRuntime().newBoolean(element.hasAttribute(key));
    }

    @Override
    public IRubyObject op_aset(ThreadContext context,
                               IRubyObject rbkey,
                               IRubyObject rbval) {
        String key = rubyStringToString(rbkey);
        String val = rubyStringToString(rbval);
        Element element = (Element) node;
        element.setAttribute(key, val);
        return this;
    }

    @Override
    public IRubyObject remove_attribute(ThreadContext context, IRubyObject name) {
        String key = name.convertToString().asJavaString();
        Element element = (Element) node;
        element.removeAttribute(key);
        return this;
    }

    @Override
    public void relink_namespace(ThreadContext context) {
        Element e = (Element) node;

        e.getOwnerDocument().renameNode(e, e.lookupNamespaceURI(e.getPrefix()), e.getNodeName());

        if(e.hasAttributes()) {
            NamedNodeMap attrs = e.getAttributes();

            for(int i = 0; i < attrs.getLength(); i++) {
                Attr attr = (Attr) attrs.item(i);
                String nsUri = "";
                String prefix = attr.getPrefix();
                String nodeName = attr.getNodeName();
                if("xml".equals(prefix)) {
                    nsUri = "http://www.w3.org/XML/1998/namespace";
                } else if("xmlns".equals(prefix) || nodeName.equals("xmlns")) {
                    nsUri = "http://www.w3.org/2000/xmlns/";
                } else {
                    nsUri = attr.lookupNamespaceURI(nodeName);
                }

                e.getOwnerDocument().renameNode(attr, nsUri, nodeName);

            }
        }

        if(e.hasChildNodes()) {
            ((XmlNodeSet) children(context)).relink_namespace(context);
        }
    }

    /**
     * TODO: previous code handled elements with parent 'p' differently?.
     */
    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        Node firstChild = node.getFirstChild();
        boolean empty = (firstChild == null);
        short type = -1;
        if (!empty) type = firstChild.getNodeType();
        boolean inline = (!empty &&
                          (type == Node.TEXT_NODE ||
                           type == Node.CDATA_SECTION_NODE ||
                           type == Node.ENTITY_REFERENCE_NODE));

        if (empty) {
            ctx.emptyTagStart(node.getNodeName());
        } else if (inline) {
            ctx.openTagInlineStart(node.getNodeName());
        } else {
            ctx.openTagStart(node.getNodeName());
        }
        
        RubyArray attr_list = namedNodeMapToRubyArray(context.getRuntime(), node.getAttributes());
        saveNodeListContent(context, attr_list, ctx);

        if (empty) {
            ctx.emptyTagEnd(node.getNodeName());
            return;
        } else if (inline) {
            ctx.openTagInlineEnd();
        } else {
            ctx.openTagEnd();
        }

        saveNodeListContent(context, (XmlNodeSet) children(context), ctx);

        if (inline) {
            ctx.closeTagInline(node.getNodeName());
        } else {
            ctx.closeTag(node.getNodeName());
        }

    }

}
