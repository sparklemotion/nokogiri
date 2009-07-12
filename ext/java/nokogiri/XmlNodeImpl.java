/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

import static nokogiri.NokogiriHelpers.isNamespace;

/**
 *
 * @author sergio
 */
class XmlNodeImpl {

    protected IRubyObject content, doc, name, namespace, namespace_definitions;

    private Node node;

    private static final IRubyObject DEFAULT_CONTENT = null;
    private static final IRubyObject DEFAULT_DOC = null;
    private static final IRubyObject DEFAULT_NAME = null;
    private static final IRubyObject DEFAULT_NAMESPACE = null;
    private static final IRubyObject DEFAULT_NAMESPACE_DEFINITIONS = null;

    public XmlNodeImpl(Ruby ruby, Node node) {
        this.node = node;
        if(node != null) {
            this.name = ruby.newString(NokogiriHelpers.getNodeName(node));
        }
    }

    public RubyString getContent(ThreadContext context) {
        if(this.content == DEFAULT_CONTENT) {
            String textContent = this.node.getTextContent();
            this.content = (textContent == null) ? context.getRuntime().newString() :
                context.getRuntime().newString(textContent);
        }

        return (RubyString) this.content;
    }

    public XmlDocument getDocument(ThreadContext context) {
        if(this.doc == DEFAULT_DOC) {
            this.doc = new XmlDocument(context.getRuntime(), this.node.getOwnerDocument());
        }

        return (XmlDocument) this.doc;
    }

    public IRubyObject getNamespace(ThreadContext context) {
        if(this.namespace == DEFAULT_NAMESPACE) {
            this.namespace = new XmlNamespace(context.getRuntime(), this.node.getPrefix(),
                                this.node.lookupNamespaceURI(this.node.getPrefix()));
            if(((XmlNamespace) this.namespace).isEmpty()) {
                this.namespace = context.getRuntime().getNil();
            }
        }

        return this.namespace;
    }

    public RubyString getNodeName(ThreadContext context) {
        if(this.name == DEFAULT_NAME) {
            this.name = context.getRuntime().newString(this.node.getNodeName());
        }

        return (RubyString) this.name;
    }

    public RubyArray getNsDefinitions(Ruby ruby) {
        if(this.namespace_definitions == DEFAULT_NAMESPACE_DEFINITIONS) {
            RubyArray arr = ruby.newArray();
            NamedNodeMap nodes = this.node.getAttributes();

            if(nodes == null) {
                return ruby.newEmptyArray();
            }

            for(int i = 0; i < nodes.getLength(); i++) {
                Node n = nodes.item(i);
                if(isNamespace(n)) {
                    arr.append(XmlNamespace.fromNode(ruby, n));
                }
            }

            this.namespace_definitions = arr;
        }

        return (RubyArray) this.namespace_definitions;
    }

    public void resetContent() {
        this.content = DEFAULT_CONTENT;
    }

    public void resetDocument() {
        this.doc = DEFAULT_DOC;
    }

    public void resetName() {
        this.name = DEFAULT_NAME;
    }

    public void resetNamespace() {
        this.namespace = DEFAULT_NAMESPACE;
    }

    public void resetNamespaceDefinitions() {
        this.namespace_definitions = DEFAULT_NAMESPACE_DEFINITIONS;
    }

    public void setContent(IRubyObject content) {
        this.content = content;
    }

    public void setDocument(IRubyObject doc) {
        this.doc = doc;
    }

    public void setName(IRubyObject name) {
        this.name = name;
    }

    public void setNamespace(IRubyObject ns) {
        this.namespace = ns;
    }

    public void setNamespaceDefinitions(IRubyObject namespace_definitions) {
        this.namespace_definitions = namespace_definitions;
    }
}
