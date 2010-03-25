package nokogiri;

import nokogiri.internals.XmlEntityDeclImpl;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.w3c.dom.Node;

/**
 * ENTITY declaration of DTD
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlEntityDecl extends XmlNode implements XmlDtdDeclaration {

    public XmlEntityDecl(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    public XmlEntityDecl(Ruby runtime, RubyClass klazz, Node entity) {
        super(runtime, klazz, entity);
        internalNode = new XmlEntityDeclImpl(runtime, entity);
    }
    
    public void setDeclaration(String declaration) {
        ((XmlEntityDeclImpl)internalNode).setDeclaration(declaration);
    }
}
