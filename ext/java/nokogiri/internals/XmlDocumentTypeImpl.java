package nokogiri.internals;

import java.util.StringTokenizer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import nokogiri.XmlAttributeDecl;
import nokogiri.XmlElementDecl;
import nokogiri.XmlEntityDecl;
import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;
import nokogiri.XmlNotation;

import org.apache.xerces.dom.DeferredAttrNSImpl;
import org.apache.xerces.dom.DeferredDocumentTypeImpl;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.DocumentType;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

/**
 * Document Type node implementation. This class represents DOCTYPE declaration.
 * 
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlDocumentTypeImpl extends XmlNodeImpl {
    private RubyHash entities = null;
    private RubyHash elements = null;
    private RubyHash attributes = null;
    private RubyHash notations = null;

    public XmlDocumentTypeImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }
    
    public IRubyObject getSystemId(ThreadContext context) {
        return JavaUtil.convertJavaToRuby(context.getRuntime(), ((DocumentType)getNode()).getSystemId());
    }
    
    public IRubyObject getPublicId(ThreadContext context) {
        return JavaUtil.convertJavaToRuby(context.getRuntime(), ((DocumentType)getNode()).getPublicId());
    }

    public IRubyObject getEntities(ThreadContext context) {
        if (entities == null) {
            initEntities(context);
        }
        return entities;
    }
    
    public IRubyObject getElements(ThreadContext context) {
        if (elements == null) {
            initElements(context);
        }
        return elements;
    }
    
    public IRubyObject getAttributes(ThreadContext context) {
        if (attributes == null) {
            initElements(context);
        }
        return attributes;
    }
    
    public IRubyObject getNotations(ThreadContext context) {
        if (notations == null) {
            initNotations(context);
        }
        return notations;
    }
    
    public IRubyObject children(ThreadContext context, XmlNode current) {
        XmlNodeSet nodeSet = getXmlNodeSet(context, current);
        nodeSet.setDocument(this.getDocument(context));
        return nodeSet;
    }

    private XmlNodeSet getXmlNodeSet(ThreadContext context, XmlNode current) {
        initEntities(context);
        initElements(context);
        //initNotations(context); // NOTATION is not XmlNode
        XmlNodeSet nodeSet = (XmlNodeSet) XmlNodeSet.newEmptyNodeSet(context);
        parseInternalSubsetString(context, nodeSet, ((org.w3c.dom.DocumentType)current.node()).getInternalSubset());
        return nodeSet;
    }
    
    private static Pattern p = Pattern.compile("<!(ATTLIST|ELEMENT|ENTITY)(\\s)(.*)");
    private static String[] startWiths = {"<!ENTITY", "<!ELEMENT", "<!ATTLIST"};
    
    private void parseInternalSubsetString(ThreadContext context, XmlNodeSet nodeSet, String str) {
        RubyHash[] namedNodeMaps = {entities, elements, attributes, notations};
        Matcher m = p.matcher(str);
        while (m.find()) {
            String decl = m.group();
            for (int i=0; i<startWiths.length; i++) {
                if (decl.startsWith(startWiths[i])) {
                    if (decl.contains("><!")) {
                        IRubyObject name = getName(context, startWiths[i].substring(2, startWiths[i].length()), decl.substring(startWiths[i].length() + 1, decl.indexOf("><!")));
                        IRubyObject[] args = {name};
                        nodeSet.push(context, namedNodeMaps[i].fetch(context, args, Block.NULL_BLOCK));
                        parseInternalSubsetString(context, nodeSet, decl.substring(startWiths[i].length() + 1, decl.length()));
                    } else {
                        IRubyObject name = getName(context, startWiths[i].substring(2, startWiths[i].length()), decl.substring(startWiths[i].length() + 1, decl.length() - 1));
                        IRubyObject[] args = {name};
                        nodeSet.push(context, namedNodeMaps[i].fetch(context, args, Block.NULL_BLOCK));
                    }
                }
            }
        }
    }
    
    private IRubyObject getName(ThreadContext context, String type, String str) {
        StringTokenizer st = new StringTokenizer(str);
        String name = st.nextToken();
        if ("ATTLIST".equals(type)) {
            name = st.nextToken();
        }
        return RubyString.newUnicodeString(context.getRuntime(), name);
    }
    
    private void initEntities(ThreadContext context) {
        if (entities != null) return;
        entities = RubyHash.newHash(context.getRuntime());
        NamedNodeMap nodes = ((DeferredDocumentTypeImpl) getNode()).getEntities();
        for (int i = 0; i < nodes.getLength(); i++) {
            Node node = nodes.item(i);
            IRubyObject key = JavaUtil.convertJavaToRuby(context.getRuntime(), node.getNodeName());
            IRubyObject value = new XmlEntityDecl(context.getRuntime(), (RubyClass) context.getRuntime().getClassFromPath("Nokogiri::XML::EntityDecl"), node);
            entities.op_aset(context, key, value);
        }
    }
    
    private void initElements(ThreadContext context) {
        if (elements != null) return;
        elements = RubyHash.newHash(context.getRuntime());
        attributes = RubyHash.newHash(context.getRuntime());
        NamedNodeMap elementMap = ((DeferredDocumentTypeImpl)getNode()).getElements();
        for (int i=0; i<elementMap.getLength(); i++) {
            Node element_node = elementMap.item(i);
            IRubyObject element_key = JavaUtil.convertJavaToRuby(context.getRuntime(), element_node.getNodeName());
            IRubyObject element_value = new XmlElementDecl(context.getRuntime(), (RubyClass)context.getRuntime().getClassFromPath("Nokogiri::XML::ElementDecl"), element_node);
            elements.op_aset(context, element_key, element_value);
            NamedNodeMap attributeMap = ((org.apache.xerces.dom.DeferredElementDefinitionImpl)elementMap.item(i)).getAttributes();
            for (int j=0; j<attributeMap.getLength(); j++) {
                DeferredAttrNSImpl attr_node = (DeferredAttrNSImpl) attributeMap.item(j);
                IRubyObject attr_key = JavaUtil.convertJavaToRuby(context.getRuntime(), attr_node.getLocalName());
                IRubyObject attr_value = new XmlAttributeDecl(context.getRuntime(), (RubyClass)context.getRuntime().getClassFromPath("Nokogiri::XML::AttributeDecl"), attr_node, element_node);
                attributes.op_aset(context, attr_key, attr_value);
            }
        }
    }
    
    private void initNotations(ThreadContext context) {
        if (notations != null) return;
        notations = RubyHash.newHash(context.getRuntime());
        NamedNodeMap nodes = ((DeferredDocumentTypeImpl)getNode()).getNotations();
        for (int i=0; i<nodes.getLength(); i++) {
            Node node = nodes.item(i);
            IRubyObject key = JavaUtil.convertJavaToRuby(context.getRuntime(), node.getNodeName());
            IRubyObject value = new XmlNotation(context.getRuntime(), (RubyClass)context.getRuntime().getClassFromPath("Nokogiri::XML::Notation"), node);
            notations.op_aset(context, key, value);
        }
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 10; }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        // FIX ME: this method is not fully implemented.
        ctx.append("<!DOCTYPE ");
        ctx.append(current.node_name(context).convertToString().asJavaString());
        IRubyObject content = current.content(context);
        if(!content.isNil()) {
            ctx.append(content.convertToString().asJavaString());
        }
        ctx.append(">");
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {
        saveContent(context, current, ctx);
    }

}
