package nokogiri.internals;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import nokogiri.XmlDocument;
import nokogiri.XmlNamespace;

import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;

/**
 *
 * @author sergio
 */
public class NokogiriNamespaceCache {

    private Map<Long, XmlNamespace> cache;
    private XmlNamespace defaultNamespace = null;

    public NokogiriNamespaceCache() {
        this.cache = new HashMap<Long, XmlNamespace>();
    }
    
    private Long hashCode(String prefix, String href) {
        long prefix_hash = prefix.hashCode();
        long href_hash = href.hashCode();
        return prefix_hash << 31 | href_hash;
    }

    public XmlNamespace get(ThreadContext context, String prefix, String href) {
        // prefix is not supposed to be null.
        // In case of a default namespace, an empty string should be given to prefix argument.
        if (prefix == null || href == null) return null;
        Long hash = hashCode(prefix, href);
        if (cache.containsKey(hash)) {
            return cache.get(hash);
        } else {
            return null;
        }
    }
    
    public XmlNamespace getDefault() {
        return defaultNamespace;
    }
    
    public XmlNamespace get(String prefix) {
        if (prefix == null) return defaultNamespace;
        long h = prefix.hashCode();
        Long hash = h << 31;
        Long mask = 0xFF00L;
        Set<Long> keys = cache.keySet();
        for (Long key : keys) {
            if ((key & mask) == hash) {
                return cache.get(key);
            }
        }
        return null;
    }
    
    public XmlNamespace put(Ruby ruby, String prefix, String href, XmlDocument document) {
        if (prefix == null || href == null) return null;
        Long hash = hashCode(prefix, href);
        if (cache.containsKey(hash)) {
            return cache.get(hash);
        } else {
            String actualPrefix = (prefix.equals("")) ? null : prefix;
            XmlNamespace namespace = new XmlNamespace(ruby, actualPrefix, href);
            namespace.setDocument(document);
            cache.put(hash, namespace);
            if ("".equals(prefix)) defaultNamespace = namespace;
            return namespace;
        }
    }

    public void remove(String prefix, String href) {
        if (prefix == null || href == null) return;
        Long hash = hashCode(prefix, href);
        if (cache.containsKey(hash)) {
            cache.remove(hash);
        }
    }
}
