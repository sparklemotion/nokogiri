package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.isNamespace;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import nokogiri.XmlNamespace;

import org.w3c.dom.Attr;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

/**
 * Cache of namespaces of each node. XmlDocument has one cache of this class.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriNamespaceCache
{

  private final Map<CacheKey, CacheEntry> cache;  // pair of the index of a given key and entry
  private XmlNamespace defaultNamespace = null;

  public
  NokogiriNamespaceCache()
  {
    this.cache = new LinkedHashMap<CacheKey, CacheEntry>(4);
  }

  public
  NokogiriNamespaceCache(NokogiriNamespaceCache cache)
  {
    this.cache = new LinkedHashMap<CacheKey, CacheEntry>(cache.size() + 2);
    this.cache.putAll(cache.cache);
  }

  public XmlNamespace
  getDefault()
  {
    return defaultNamespace;
  }

  public XmlNamespace
  get(String prefix, String href)
  {
    if (href == null) { return null; }

    CacheEntry value = cache.get(new CacheKey(prefix, href));
    return value == null ? null : value.namespace;
  }

  public XmlNamespace
  get(Node node, String prefix)
  {
    if (prefix == null) { return defaultNamespace; }
    for (Map.Entry<CacheKey, CacheEntry> entry : cache.entrySet()) {
      if (entry.getKey().prefix.equals(prefix)) {
        if (entry.getValue().isOwner(node)) {
          return entry.getValue().namespace;
        }
      }
    }
    return null;
  }

  public List<XmlNamespace>
  get(String prefix)
  {
    List<XmlNamespace> namespaces = new ArrayList<XmlNamespace>();
    if (prefix == null) {
      namespaces.add(defaultNamespace);
      return namespaces;
    }
    for (Map.Entry<CacheKey, CacheEntry> entry : cache.entrySet()) {
      if (entry.getKey().prefix.equals(prefix)) {
        namespaces.add(entry.getValue().namespace);
      }
    }
    return namespaces;
  }

  public List<XmlNamespace>
  get(Node node)
  {
    List<XmlNamespace> namespaces = new ArrayList<XmlNamespace>();
    for (Map.Entry<CacheKey, CacheEntry> entry : cache.entrySet()) {
      if (entry.getValue().isOwner(node)) {
        namespaces.add(entry.getValue().namespace);
      }
    }
    return namespaces;
  }

  public void
  put(XmlNamespace namespace, Node ownerNode)
  {
    String prefix = namespace.getPrefix();
    String href = namespace.getHref();
    if (href == null) { return; }

    CacheKey key = new CacheKey(prefix, href);
    if (cache.get(key) != null) { return; }
    cache.put(key, new CacheEntry(namespace, ownerNode));
    if ("".equals(prefix)) { defaultNamespace = namespace; }
  }

  public void
  remove(Node ownerNode)
  {
    String prefix = ownerNode.getPrefix();
    String href = ownerNode.getNamespaceURI();
    if (href == null) { return; }

    cache.remove(new CacheKey(prefix, href));
  }

  public int
  size()
  {
    return cache.size();
  }

  public void
  clear()
  {
    // removes namespace declarations from node
    for (CacheEntry entry : cache.values()) {
      NamedNodeMap attributes = entry.ownerNode.getAttributes();
      for (int j = 0; j < attributes.getLength(); j++) {
        String name = ((Attr) attributes.item(j)).getName();
        if (isNamespace(name)) {
          attributes.removeNamedItem(name);
        }
      }
    }
    cache.clear();
    defaultNamespace = null;
  }

  public void
  replaceNode(Node oldNode, Node newNode)
  {
    for (Map.Entry<CacheKey, CacheEntry> entry : cache.entrySet()) {
      if (entry.getValue().isOwner(oldNode)) {
        entry.getValue().replaceOwner(newNode);
      }
    }
  }

  @Override
  public String
  toString()
  {
    return getClass().getName() + '@' + Integer.toHexString(hashCode()) + '(' + cache + "default=" + defaultNamespace + ')';
  }

  private static class CacheKey
  {
    final String prefix;
    final String href;

    CacheKey(String prefix, String href)
    {
      this.prefix = prefix;
      this.href = href;
    }

    @Override
    public boolean
    equals(final Object obj)
    {
      if (obj instanceof CacheKey) {
        CacheKey that = (CacheKey) obj;
        return prefix == null ? that.prefix == null : prefix.equals(that.prefix) && href.equals(that.href);
      }
      return false;
    }

    @Override
    public int
    hashCode()
    {
      return (prefix == null ? 0 : prefix.hashCode()) + 37 * href.hashCode();
    }

    @Override
    public String
    toString()
    {
      return '[' + prefix + ']' + href;
    }
  }

  private static class CacheEntry
  {
    final XmlNamespace namespace;
    private Node ownerNode;

    CacheEntry(XmlNamespace namespace, Node ownerNode)
    {
      this.namespace = namespace;
      this.ownerNode = ownerNode;
    }

    boolean
    isOwner(Node node)
    {
      return ownerNode.isSameNode(node);
    }

    void
    replaceOwner(Node newNode)
    {
      this.ownerNode = newNode;
    }

    @Override
    public String
    toString()
    {
      return namespace.toString();
    }
  }
}
