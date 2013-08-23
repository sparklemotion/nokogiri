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

package nokogiri.internals;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import nokogiri.XmlNamespace;

import org.w3c.dom.Attr;
import org.w3c.dom.Node;

/**
 * Cache of namespages of each node. XmlDocument has one cache of this class.
 * 
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriNamespaceCache {

    private Map<Node, Map<String, XmlNamespace>> cache;  // pair of the index of a given key and entry
    private XmlNamespace defaultNamespace = null;

    public NokogiriNamespaceCache() {
        cache = new LinkedHashMap<Node, Map<String, XmlNamespace>>();
    }
    
    private Map<String, XmlNamespace> getNodeCache(Node node){
    	Map<String, XmlNamespace> nodeMap = cache.get(node);
    	if(nodeMap == null){
    		nodeMap = new LinkedHashMap<String, XmlNamespace>();
    		cache.put(node, nodeMap);
    	   }
    	return nodeMap;
    }
    
    public XmlNamespace get(String prefix, Node node) {
        // prefix should not be null.
        // In case of a default namespace, an empty string should be given to prefix argument.       
        return getNodeCache(node).get(prefix);
    }
 
    public XmlNamespace getFromHierarchy(String prefix, Node node){
    	if(node == null) return null;
    	XmlNamespace namespace = get(prefix,node);
    	if(namespace == null){
    		Node owner = node.getParentNode();
    		if(node instanceof Attr){
    			owner = ((Attr)node).getOwnerElement();
    		}
    	    if(owner != node.getOwnerDocument()  ){
    	    	namespace = getFromHierarchy(prefix,owner);
    	    }
    	}
    	return namespace;
    }
    
    public XmlNamespace getDefault(Node node) {
        return getFromHierarchy("", node);
    }
    
    public List<XmlNamespace> get(Node node) {
        List<XmlNamespace> namespaces = new ArrayList<XmlNamespace>();
        Map<String, XmlNamespace> nodeMap = getNodeCache(node);
        namespaces.addAll( nodeMap.values());
        return namespaces;
    }

    public void put(XmlNamespace namespace, Node node) {
    	// only add if there is not a prefix mapping already, this is consitent with C Ruby nokogiri 
    	//implementation
    	XmlNamespace have = getFromHierarchy(namespace.getPrefix(),node);
    	if(have != null && have.getHref().equals(namespace.getHref())){
    		return;
    	}
        String prefixString = namespace.getPrefix();
        Map<String, XmlNamespace> nodeMap = getNodeCache(node);
        if(nodeMap.get(prefixString) == null){
        	nodeMap.put(prefixString, namespace);
        }
    }

    public void remove(String prefix, Node node) {
    	 getNodeCache(node).remove(prefix);
    }
    
    public void clear() {
        cache.clear();
        defaultNamespace = null;
    }
    
    public void replaceNode(Node oldNode, Node newNode) {
        cache.put(newNode, cache.get(oldNode));
        cache.remove(oldNode);
    }
}
