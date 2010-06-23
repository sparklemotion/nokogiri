package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.isNamespace;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import nokogiri.XmlDocument;
import nokogiri.XmlNamespace;

import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Attr;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriNamespaceCache {

    private List<Long> keys;  // order matters.
    private Map<Integer, CacheEntry> cache;  // pair of the index of a given key and entry
    private XmlNamespace defaultNamespace = null;

    public NokogiriNamespaceCache() {
        keys = new ArrayList<Long>();
        cache = new HashMap<Integer, CacheEntry>();
    }
    
    private Long hashCode(String prefix, String href) {
        long prefix_hash = prefix.hashCode();
        long href_hash = href.hashCode();
        return prefix_hash << 31 | href_hash;
    }

    public XmlNamespace get(String prefix, String href) {
        // prefix should not be null.
        // In case of a default namespace, an empty string should be given to prefix argument.
        if (prefix == null || href == null) return null;
        Long hash = hashCode(prefix, href);
        Integer index = keys.indexOf(hash);
        if (index != -1) return cache.get(index).namespace;
        return null;
    }
    
    public XmlNamespace getDefault() {
        return defaultNamespace;
    }
    
    public XmlNamespace get(String prefix) {
        if (prefix == null) return defaultNamespace;
        long h = prefix.hashCode();
        Long hash = h << 31;
        Long mask = 0xFF00L;
        for (int i=0; i < keys.size(); i++) {
            if ((keys.get(i) & mask) == hash) {
                return cache.get(i).namespace;
            }
        }
        return null;
    }
    
    public List<XmlNamespace> get(Node node) {
        List<XmlNamespace> namespaces = new ArrayList<XmlNamespace>();
        for (int i=0; i < keys.size(); i++) {
            CacheEntry entry = cache.get(i);
            if (entry.node == node) {
                namespaces.add(entry.namespace);
            }
        }
        return namespaces;
    }
    
    public XmlNamespace put(Ruby ruby, String prefix, String href, Node node, XmlDocument document) {
        // prefix should not be null.
        // In case of a default namespace, an empty string should be given to prefix argument.
        if (prefix == null || href == null) return null;
        Long hash = hashCode(prefix, href);
        Integer index;
        if ((index = keys.indexOf(hash)) != -1) {
            return cache.get(index).namespace;
        } else {
            keys.add(hash);
            index = keys.size() - 1;
            String actualPrefix = (prefix.equals("")) ? null : prefix;
            XmlNamespace namespace = new XmlNamespace(ruby, actualPrefix, href);
            namespace.setDocument(document);
            CacheEntry entry = new CacheEntry(namespace, node);
            cache.put(index, entry);
            if ("".equals(prefix)) defaultNamespace = namespace;
            return namespace;
        }
    }

    public void remove(String prefix, String href) {
        if (prefix == null || href == null) return;
        Long hash = hashCode(prefix, href);
        Integer index = keys.indexOf(hash);
        if (index != -1) {
            cache.remove(index);
        }
        keys.remove(index);
    }
    
    public void clear() {
        // removes namespace declarations from node
        for (int i=0; i < keys.size(); i++) {
            CacheEntry entry = cache.get(i);
            NamedNodeMap attributes = entry.node.getAttributes();
            for (int j=0; j<attributes.getLength(); j++) {
                String name = ((Attr)attributes.item(j)).getName();
                if (isNamespace(name)) {
                    attributes.removeNamedItem(name);
                }
            }
        }
        keys.clear();
        cache.clear();
        defaultNamespace = null;
    }
    
    private class CacheEntry {
        private XmlNamespace namespace;
        private Node node;
        
        CacheEntry(XmlNamespace namespace, Node node) {
            this.namespace = namespace;
            this.node = node;
        }
    }
}
