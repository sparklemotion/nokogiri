package nokogiri;

import java.util.Hashtable;
import java.util.Iterator;
import javax.xml.XMLConstants;
import javax.xml.namespace.NamespaceContext;

public class NokogiriNamespaceContext implements NamespaceContext{

    Hashtable<String,String> register;

    public NokogiriNamespaceContext(){
        this.register = new Hashtable<String,String>();
    }

    public String getNamespaceURI(String prefix){
        if(prefix == null) {
            throw new IllegalArgumentException();
        } else if(prefix.equals(XMLConstants.XML_NS_PREFIX)) {
            return XMLConstants.XML_NS_URI;
        } else if(prefix.equals(XMLConstants.XMLNS_ATTRIBUTE)) {
            return XMLConstants.XMLNS_ATTRIBUTE_NS_URI;
        }

        String uri = this.register.get(prefix);
        if(uri != null) {
            return uri;
        }

        return XMLConstants.NULL_NS_URI;
    }

    public String getPrefix(String uri){
        throw new UnsupportedOperationException();
    }

    public Iterator getPrefixes(String uri){
        throw new UnsupportedOperationException();
    }

    public void registerNamespace(String prefix, String uri){
        this.register.put(prefix, uri);
    }
}