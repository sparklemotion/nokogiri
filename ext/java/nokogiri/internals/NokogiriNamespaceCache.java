/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri.internals;

import nokogiri.*;
import java.util.Hashtable;
import org.jruby.runtime.ThreadContext;

/**
 *
 * @author sergio
 */
public class NokogiriNamespaceCache {

    Hashtable<String, Hashtable<String,XmlNamespace>> cache;

    public NokogiriNamespaceCache() {
        this.cache = new Hashtable<String, Hashtable<String,XmlNamespace>>();
    }

    public XmlNamespace get(ThreadContext context, XmlNode node, String prefix, String href) {
        Hashtable<String,XmlNamespace> secondCache = this.cache.get(prefix);

        if(secondCache == null) {
            secondCache = new Hashtable<String,XmlNamespace>();
            this.cache.put(prefix, secondCache);
        }

        if (href == null) return null;
        XmlNamespace ns = secondCache.get(href);

        if( ns == null) {
            String actualPrefix = (prefix.equals("")) ? null : prefix;
            ns = new XmlNamespace(context.getRuntime(), actualPrefix, href);
            ns.setDocument(node.document(context));
            secondCache.put(href, ns);
        }

        return ns;
    }

}
