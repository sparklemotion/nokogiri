package nokogiri.internals;

import nokogiri.XmlNamespace;
import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 *
 * @author sergio
 */
public class XmlElementImpl extends XmlNodeImpl {

    public XmlElementImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    public void add_namespace_definitions(ThreadContext context, XmlNode current, XmlNamespace ns, String prefix, String href) {
        Element e = (Element) current.getNode();
        e.setAttribute(prefix, href);

        current.updateNodeNamespaceIfNecessary(context, ns);
    }

    @Override
    public IRubyObject get(ThreadContext context, XmlNode current, IRubyObject key) {
        String keyString = key.convertToString().asJavaString();
        Element element = (Element) current.getNode();
        String value = element.getAttribute(keyString);
        if(!value.equals("")){
            return RubyString.newString(context.getRuntime(), value);
        }
        return context.getRuntime().getNil();
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 1; }

    @Override
    public boolean isElement() { return true; }

    @Override
    public IRubyObject key_p(ThreadContext context, XmlNode current, IRubyObject k) {
        Ruby ruby = context.getRuntime();
        String key = k.convertToString().asJavaString();
        Element element = (Element)current.getNode();
        return ruby.newBoolean(element.hasAttribute(key));
    }

    @Override
    public void node_name_set(ThreadContext context, XmlNode current, IRubyObject nodeName) {
        String newName = nodeName.convertToString().asJavaString();
        current.getNode().getOwnerDocument().renameNode(current.getNode(), null, newName);
        current.setName(nodeName);
    }

    @Override
    public void op_aset(ThreadContext context, XmlNode current, IRubyObject index, IRubyObject val) {
        String key = index.convertToString().asJavaString();
        String value = val.convertToString().asJavaString();
        Element element = (Element)current.getNode();
        element.setAttribute(key, value);
    }

    @Override
    public void remove_attribute(ThreadContext context, XmlNode current, IRubyObject name) {
        String key = name.convertToString().asJavaString();
        Element element = (Element)current.getNode();
        element.removeAttribute(key);
    }

    @Override
    public void relink_namespace(ThreadContext context, XmlNode node) {
        Element e = (Element) node.getNode();

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
            ((XmlNodeSet) node.children(context)).relink_namespace(context);
        }
    }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        boolean format = ctx.format();

        Element e = (Element) current.getNode();

        if(format) {
            NodeList tmp = e.getChildNodes();
            for(int i = 0; i < tmp.getLength(); i++) {
                Node cur = tmp.item(i);
                if(cur.getNodeType() == Node.TEXT_NODE ||
                        cur.getNodeType() == Node.CDATA_SECTION_NODE ||
                        cur.getNodeType() == Node.ENTITY_REFERENCE_NODE) {
                    ctx.setFormat(false);
                    break;
                }
            }
        }

        ctx.append("<");
        ctx.append(e.getNodeName());
        RubyArray attr_list = NokogiriHelpers.namedNodeMapToRubyArray(context.getRuntime(), current.getNode().getAttributes());
        this.saveNodeListContent(context, attr_list, ctx);

        if(e.getChildNodes() == null && !ctx.noEmpty()) {
            ctx.append("/>");
            ctx.setFormat(format);
            return;
        }

        ctx.append(">");

//        ctx.append(current.content(context).convertToString().asJavaString());

        XmlNodeSet children = (XmlNodeSet) current.children(context);

        if(!children.isEmpty()) {
            if(ctx.format()) ctx.append("\n");
            ctx.increaseLevel();
            this.saveNodeListContent(context, children, ctx);
            ctx.decreaseLevel();
            if(ctx.format()) ctx.append(ctx.getCurrentIndentString());
        }

        ctx.append("</");
        ctx.append(e.getNodeName());
        ctx.append(">");

        ctx.setFormat(format);
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {

        Element e = (Element) current.getNode();


        ctx.append("<");
        ctx.append(e.getNodeName());
        this.saveNodeListContentAsHtml(context, (RubyArray) current.attribute_nodes(context), ctx);

        ctx.append(">");

        Node next = e.getFirstChild();
        Node parent = e.getParentNode();
        if(ctx.format() && next != null &&
                next.getNodeType() != Node.TEXT_NODE &&
                next.getNodeType() != Node.ENTITY_REFERENCE_NODE &&
                parent != null &&
                parent.getNodeName() != null &&
                parent.getNodeName().charAt(0) != 'p'){
            ctx.append("\n");
        }

        if(e.getChildNodes().getLength() == 0) {
            ctx.append("</");
            ctx.append(e.getNodeName());
            ctx.append(">");
            if(ctx.format() && next != null &&
                next.getNodeType() != Node.TEXT_NODE &&
                next.getNodeType() != Node.ENTITY_REFERENCE_NODE &&
                parent != null &&
                parent.getNodeName() != null &&
                parent.getNodeName().charAt(0) != 'p'){
                ctx.append("\n");
            }
            return;
        }

        XmlNodeSet children = (XmlNodeSet) current.children(context);

        if(!children.isEmpty()) {
            if(ctx.format() && next != null &&
                next.getNodeType() != Node.TEXT_NODE &&
                next.getNodeType() != Node.ENTITY_REFERENCE_NODE &&
                parent != null &&
                parent.getNodeName() != null &&
                parent.getNodeName().charAt(0) != 'p'){
                ctx.append("\n");
            }
            this.saveNodeListContentAsHtml(context, children, ctx);
            if(ctx.format() && next != null &&
                next.getNodeType() != Node.TEXT_NODE &&
                next.getNodeType() != Node.ENTITY_REFERENCE_NODE &&
                parent != null &&
                parent.getNodeName() != null &&
                parent.getNodeName().charAt(0) != 'p'){
                ctx.append("\n");
            }
        }

        ctx.append("</");
        ctx.append(e.getNodeName());
        ctx.append(">");

        if(ctx.format() && next != null &&
            next.getNodeType() != Node.TEXT_NODE &&
            next.getNodeType() != Node.ENTITY_REFERENCE_NODE &&
            parent != null &&
            parent.getNodeName() != null &&
            parent.getNodeName().charAt(0) != 'p'){
            ctx.append("\n");
        }
    }
}
