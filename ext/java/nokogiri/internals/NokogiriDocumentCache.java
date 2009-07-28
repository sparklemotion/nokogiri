package nokogiri.internals;

import java.util.Hashtable;
import nokogiri.XmlDocument;
import org.w3c.dom.Document;

/**
 *
 * @author sergio
 */
public class NokogiriDocumentCache {

    private static NokogiriDocumentCache instance;
    protected Hashtable<Document, XmlDocument> cache;

    private NokogiriDocumentCache() {
        this.cache = new Hashtable<Document, XmlDocument>();
    }

    public static NokogiriDocumentCache getInstance() {
        if(instance == null) {
            instance = new NokogiriDocumentCache();
        }
        return instance;
    }

    public XmlDocument getXmlDocument(Document doc) {
        return this.cache.get(doc);
    }

    public void putDocument(Document doc, XmlDocument xmlDoc) {
        this.cache.put(doc, xmlDoc);
    }

    public XmlDocument removeDocument(Document doc) {
        return this.cache.remove(doc);
    }

}
