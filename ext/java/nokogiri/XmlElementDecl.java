package nokogiri;

import nokogiri.internals.XmlElementDeclImpl;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.w3c.dom.Node;

/**
 * ELEMENT declaration of DTD
 * 
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlElementDecl extends XmlNode {

    public XmlElementDecl(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    public XmlElementDecl(Ruby runtime, RubyClass klazz, Node entity) {
        super(runtime, klazz, entity);
        internalNode = new XmlElementDeclImpl(runtime, entity);
    }
}
