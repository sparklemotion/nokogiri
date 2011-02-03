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

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.nodeListToRubyArray;

import java.util.List;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Class for Nokogiri::XML::NodeSet
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name="Nokogiri::XML::NodeSet")
public class XmlNodeSet extends RubyObject {
    private NodeList nodeList;
    private RubyArray nodes;
    private IRubyObject doc;
    
    public XmlNodeSet(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
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

    public XmlNodeSet(Ruby ruby, NodeList nodes) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::NodeSet"), nodes);
    }

    public XmlNodeSet(Ruby ruby, RubyArray nodes) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::NodeSet"), nodes);
    }

    public XmlNodeSet(Ruby ruby, RubyClass rubyClass, NodeList nodes) {
        this(ruby, rubyClass, nodeListToRubyArray(ruby, nodes));
        nodeList = nodes;
    }

    public XmlNodeSet(Ruby ruby, RubyClass rubyClass, RubyArray nodes){
        super(ruby, rubyClass);
        this.nodes = nodes;
        
        IRubyObject first = nodes.first();
        initialize(ruby, first);
    }
    
    public XmlNodeSet(Ruby ruby, XmlNodeSet reference){
        super(ruby, getNokogiriClass(ruby, "Nokogiri::XML::NodeSet"));
        this.nodes = null;
        
        IRubyObject first = reference.nodes.first();
        initialize(ruby, first);
    }
    
    void setNodes(RubyArray nodes) {
        this.nodes = nodes;
        nodeList = null;
    }
    
    public void setInitialNodes(RubyArray nodes) {
        this.nodes = nodes;
        IRubyObject first = nodes.first();
        initialize(getRuntime(), first);
    }
    
    public void setNodeList(NodeList nodeList) {
        setInitialNodes(nodeListToRubyArray(getRuntime(), nodeList));
        this.nodeList = nodeList;
    }
    
    private void initialize(Ruby ruby, IRubyObject refNode) {
        if (refNode instanceof XmlNode) {
            XmlNode n = (XmlNode)refNode;
            doc = n.document(ruby.getCurrentContext());
            setInstanceVariable("@document", doc);
            if (doc != null) {
                RuntimeHelpers.invoke(ruby.getCurrentContext(), doc, "decorate", this);
            }
        }
    }

    public static IRubyObject newEmptyNodeSet(ThreadContext context) {
        return (XmlNodeSet)NokogiriService.XML_NODESET_ALLOCATOR.allocate(context.getRuntime(), getNokogiriClass(context.getRuntime(), "Nokogiri::XML::NodeSet"));
    }

    public long length() {
        if (nodes == null) return 0L;
        return nodes.length().getLongValue();
    }

    public void relink_namespace(ThreadContext context) {
        nodeList = null;
        List<?> n = nodes.getList();

        for (int i = 0; i < n.size(); i++) {
            if (n.get(i) instanceof XmlNode) {
                ((XmlNode) n.get(i)).relink_namespace(context);
            }
        }
    }

    public void setDocument(IRubyObject document) {
        setInstanceVariable("@document", document);
        this.doc = document;
    }

    public NodeList toNodeList(Ruby ruby) {
        if (nodeList != null) return nodeList;
        return new NokogiriNodeList(ruby, this.nodes);
    }

    @JRubyMethod(name="&")
    public IRubyObject and(ThreadContext context, IRubyObject nodeSet){
        nodeList = null;
        return newXmlNodeSet(context, (RubyArray) nodes.op_and(asXmlNodeSet(context, nodeSet).nodes));
    }

    @JRubyMethod
    public IRubyObject delete(ThreadContext context, IRubyObject node_or_namespace){
        nodeList = null;
        return nodes.delete(context, asXmlNodeOrNamespace(context, node_or_namespace), Block.NULL_BLOCK);
    }

    @JRubyMethod
    public IRubyObject dup(ThreadContext context){
        return newXmlNodeSet(context, nodes.aryDup());
    }

    @JRubyMethod(name = "include?")
    public IRubyObject include_p(ThreadContext context, IRubyObject node_or_namespace){
        return nodes.include_p(context, asXmlNodeOrNamespace(context, node_or_namespace));
    }

    @JRubyMethod(name = {"length", "size"})
    public IRubyObject length(ThreadContext context) {
        if (nodes == null) setInitialNodes(RubyArray.newEmptyArray(context.getRuntime()));
        return nodes.length();
    }

    @JRubyMethod(name="-")
    public IRubyObject op_diff(ThreadContext context, IRubyObject nodeSet){
        nodeList = null;
        XmlNodeSet xmlNodeSet = newXmlNodeSet(context, this);
        xmlNodeSet.setNodes((RubyArray) nodes.op_diff(asXmlNodeSet(context, nodeSet).nodes));
        return xmlNodeSet;
    }

    @JRubyMethod(name={"|", "+"})
    public IRubyObject op_or(ThreadContext context, IRubyObject nodeSet){
        nodeList = null;
        if (nodes == null) setInitialNodes(RubyArray.newEmptyArray(context.getRuntime()));
        return newXmlNodeSet(context, (RubyArray) nodes.op_or(asXmlNodeSet(context, nodeSet).nodes));
    }

    @JRubyMethod(name = {"push", "<<"})
    public IRubyObject push(ThreadContext context, IRubyObject node_or_namespace) {
        nodeList = null;
        if (nodes == null) setInitialNodes(RubyArray.newEmptyArray(context.getRuntime()));
        nodes.append(asXmlNodeOrNamespace(context, node_or_namespace));
        return this;
    }

    @JRubyMethod(name={"[]", "slice"})
    public IRubyObject slice(ThreadContext context, IRubyObject indexOrRange){
        IRubyObject result;
        if (context.getRuntime().is1_9()) {
            result = nodes.aref19(indexOrRange);
        } else {
            result = nodes.aref(indexOrRange);
        }
        if (result instanceof RubyArray) {
            return newXmlNodeSet(context, (RubyArray)result);
        } else {
            return result;
        }
    }

    @JRubyMethod(name={"[]", "slice"})
    public IRubyObject slice(ThreadContext context, IRubyObject start, IRubyObject length){
        IRubyObject result;
        if (context.getRuntime().is1_9()) {
            result = nodes.aref19(start, length);
        } else {
            result = nodes.aref(start, length);
        }
        if (result instanceof RubyArray) return newXmlNodeSet(context, (RubyArray)result);
        else return context.getRuntime().getNil();
    }

    @JRubyMethod(name = {"to_a", "to_ary"})
    public IRubyObject to_a(ThreadContext context){
       return nodes;
    }

    @JRubyMethod(name = {"unlink", "remove"})
    public IRubyObject unlink(ThreadContext context){
        nodeList = null;
        IRubyObject[] arr = this.nodes.toJavaArrayUnsafe();
        long length = arr.length;
        for (int i = 0; i < length; i++) {
            if (arr[i] instanceof XmlNode) {
                ((XmlNode) arr[i] ).unlink(context);
            }
        }
        return this;
    }

    private XmlNodeSet newXmlNodeSet(ThreadContext context, RubyArray array) {
        XmlNodeSet xmlNodeSet = (XmlNodeSet)NokogiriService.XML_NODESET_ALLOCATOR.allocate(context.getRuntime(), getNokogiriClass(context.getRuntime(), "Nokogiri::XML::NodeSet"));
        xmlNodeSet.setInitialNodes(array);
        return xmlNodeSet;
    }
    
    private XmlNodeSet newXmlNodeSet(ThreadContext context, XmlNodeSet reference) {
        XmlNodeSet result = new XmlNodeSet(context.getRuntime(), reference);
        return result;
    }

    private IRubyObject asXmlNodeOrNamespace(ThreadContext context, IRubyObject possibleNode) {
        if (possibleNode instanceof XmlNode || possibleNode instanceof XmlNamespace) {
            return possibleNode;
        } else {
            throw context.getRuntime().newArgumentError("node must be a Nokogiri::XML::Node or Nokogiri::XML::Namespace");
        }
    }

    private XmlNodeSet asXmlNodeSet(ThreadContext context, IRubyObject possibleNodeSet) {
//        if(!(possibleNodeSet instanceof XmlNodeSet)) {
        if(!RuntimeHelpers.invoke(context, possibleNodeSet, "is_a?",
                getNokogiriClass(context.getRuntime(), "Nokogiri::XML::NodeSet")).isTrue()) {
            throw context.getRuntime().newArgumentError("node must be a Nokogiri::XML::NodeSet");
        }
        XmlNodeSet xmlNodeSet = (XmlNodeSet)possibleNodeSet;
        if (xmlNodeSet.nodes == null) xmlNodeSet.setInitialNodes(RubyArray.newEmptyArray(context.getRuntime()));
        return xmlNodeSet;
    }

    class NokogiriNodeList implements NodeList{

        private final RubyArray nodes;
        private final Ruby ruby;

        public NokogiriNodeList(Ruby ruby, RubyArray nodes) {
            this.nodes = nodes;
            this.ruby = ruby;
        }

        public Node item(int i) {
            return XmlNode.getNodeFromXmlNode(ruby.getCurrentContext(),
                    this.nodes.aref(ruby.newFixnum(i)));
        }

        public int getLength() {
            return this.nodes.getLength();
        }

    }
}
