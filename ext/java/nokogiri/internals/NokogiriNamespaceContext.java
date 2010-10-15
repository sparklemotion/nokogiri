package nokogiri.internals;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.Map.Entry;

import javax.xml.XMLConstants;
import javax.xml.namespace.NamespaceContext;

public class NokogiriNamespaceContext implements NamespaceContext {
	public static final String NOKOGIRI_PREFIX = "nokogiri";
    public static final String NOKOGIRI_URI = "http://www.nokogiri.org/default_ns/ruby/extensions_functions";
    public static final String NOKOGIRI_TEMPORARY_ROOT_TAG = "nokogiri-temporary-root-tag";
    
    private Hashtable<String,String> register;

    public NokogiriNamespaceContext() {
        this.register = new Hashtable<String,String>();
        register.put(NOKOGIRI_PREFIX, NOKOGIRI_URI);
        register.put("xml", "http://www.w3.org/XML/1998/namespace");
        register.put("xhtml", "http://www.w3.org/1999/xhtml");
    }

    public String getNamespaceURI(String prefix) {
    	if (prefix == null) {
            throw new IllegalArgumentException();
        }
        String uri = this.register.get(prefix);
        if (uri != null) {
            return uri;
        }

        if (prefix.equals(XMLConstants.XMLNS_ATTRIBUTE)) {
            uri = this.register.get(XMLConstants.XMLNS_ATTRIBUTE);
            return (uri == null) ? XMLConstants.XMLNS_ATTRIBUTE_NS_URI : uri;
        }

        return XMLConstants.NULL_NS_URI;
    }

    public String getPrefix(String uri) {
    	if (uri == null) {
            throw new IllegalArgumentException("uri is null");
        } else {
            Set<Entry<String, String>> entries = register.entrySet();
            for (Entry<String, String> entry : entries) {
                if (uri.equals(entry.getValue())) {
                    return entry.getKey();
                }
            }
        }
        return null;
    }

    public Iterator<String> getPrefixes(String uri) {
        if (register == null) return null;
        Set<Entry<String, String>> entries = register.entrySet();
        List<String> list = new ArrayList<String>();
        for (Entry<String, String> entry : entries) {
            if (uri.equals(entry.getValue())) {
                list.add(entry.getKey());
            }
        }
        return list.iterator();
    }
    
    public Set<String> getAllPrefixes() {
        if (register == null) return null;
        return register.keySet();
    }

    public void registerNamespace(String prefix, String uri) {
        if("xmlns".equals(prefix)) prefix = "";
        this.register.put(prefix, uri);
    }
}
