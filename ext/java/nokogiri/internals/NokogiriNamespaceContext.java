package nokogiri.internals;

import java.util.Hashtable;
import java.util.Iterator;
import javax.xml.XMLConstants;
import javax.xml.namespace.NamespaceContext;

public class NokogiriNamespaceContext implements NamespaceContext{

    Hashtable<String,String> register;

    public NokogiriNamespaceContext(){
        this.register = new Hashtable<String,String>();
    }

    public String getNamespaceURI(String prefix) {
//        System.out.println("Asked for " + prefix);
        String uri = this.register.get(prefix);
        if(uri != null) {
//            System.out.println("Returned "+uri);
            return uri;
        }

//        System.out.println("Returned another url");

        if(prefix == null) {
            throw new IllegalArgumentException();
        } else if(prefix.equals(XMLConstants.XMLNS_ATTRIBUTE)) {
            uri = this.register.get(XMLConstants.XMLNS_ATTRIBUTE);
            return (uri == null) ? XMLConstants.XMLNS_ATTRIBUTE_NS_URI : uri;
        }

        return XMLConstants.NULL_NS_URI;
    }

    public String getPrefix(String uri){
        return null;
    }

    public Iterator getPrefixes(String uri){
        return null;
    }

    public void registerNamespace(String prefix, String uri){
        if("xmlns".equals(prefix)) prefix = "";
//        System.out.println("Registered prefix "+prefix+" with uri " + uri);
        this.register.put(prefix, uri);
    }
}
