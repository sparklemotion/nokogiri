package nokogiri.internals;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import javax.xml.XMLConstants;
import javax.xml.namespace.NamespaceContext;

/**
 * Holder of each node's namespace.
 *
 * @author Yoko Harada <yokolet@gmail.com>
 *
 */
public final class NokogiriNamespaceContext implements NamespaceContext
{

  /*
   * these constants have matching declarations in
   * ext/nokogiri/xml_xpath_context.c
   */
  public static final String NOKOGIRI_PREFIX = "nokogiri";
  public static final String NOKOGIRI_URI = "http://www.nokogiri.org/default_ns/ruby/extensions_functions";

  public static final String NOKOGIRI_BUILTIN_PREFIX = "nokogiri-builtin";
  public static final String NOKOGIRI_BUILTIN_URI = "https://www.nokogiri.org/default_ns/ruby/builtins";

  private final Map<String, String> register;

  public static NokogiriNamespaceContext
  create()
  {
    return new NokogiriNamespaceContext();
  }

  private
  NokogiriNamespaceContext()
  {
    register = new HashMap<String, String>(6, 1);
    register.put(NOKOGIRI_PREFIX, NOKOGIRI_URI);
    register.put(NOKOGIRI_BUILTIN_PREFIX, NOKOGIRI_BUILTIN_URI);
    register.put("xml", "http://www.w3.org/XML/1998/namespace");
    register.put("xhtml", "http://www.w3.org/1999/xhtml");
  }

  public String
  getNamespaceURI(String prefix)
  {
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

  public String
  getPrefix(String uri)
  {
    if (uri == null) {
      throw new IllegalArgumentException("uri is null");
    }
    Set<Entry<String, String>> entries = register.entrySet();
    for (Entry<String, String> entry : entries) {
      if (uri.equals(entry.getValue())) {
        return entry.getKey();
      }
    }
    return null;
  }

  public Iterator<String>
  getPrefixes(String uri)
  {
    Set<Entry<String, String>> entries = register.entrySet();
    ArrayList<String> list = new ArrayList<String>(entries.size());
    for (Entry<String, String> entry : entries) {
      if (uri.equals(entry.getValue())) {
        list.add(entry.getKey());
      }
    }
    return list.iterator();
  }

  public Set<String>
  getAllPrefixes()
  {
    return register.keySet();
  }

  public void
  registerNamespace(String prefix, String uri)
  {
    if ("xmlns".equals(prefix)) { prefix = ""; }
    register.put(prefix, uri);
  }

}
