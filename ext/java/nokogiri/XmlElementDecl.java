package nokogiri;

import java.util.ArrayList;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

import static nokogiri.internals.NokogiriHelpers.getPrefix;
import static nokogiri.internals.NokogiriHelpers.getLocalPart;

/**
 * DTD element declaration.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
public class XmlElementDecl extends XmlNode {
    RubyArray attrDecls;

    IRubyObject contentModel;

    public static RubyClass getRubyClass(Ruby ruby) {
        return (RubyClass)ruby.getClassFromPath("Nokogiri::XML::ElementDecl");
    }

    public XmlElementDecl(Ruby ruby, RubyClass klass) {
        super(ruby, klass);
        throw ruby.newRuntimeError("node required");
    }

    /**
     * Initialize based on an elementDecl node from a NekoDTD parsed
     * DTD.
     */
    public XmlElementDecl(Ruby ruby, RubyClass klass, Node elemDeclNode) {
        super(ruby, klass, elemDeclNode);
        attrDecls = RubyArray.newArray(ruby);
        contentModel = ruby.getNil();
    }

    public static IRubyObject create(ThreadContext context, Node elemDeclNode) {
        XmlElementDecl self =
            new XmlElementDecl(context.getRuntime(),
                               getRubyClass(context.getRuntime()),
                               elemDeclNode);
        return self;
    }

    public IRubyObject element_name(ThreadContext context) {
        return getAttribute(context, "ename");
    }

    public void setContentModel(IRubyObject cm) {
        contentModel = cm;
    }

    @Override
    @JRubyMethod
    public IRubyObject content(ThreadContext context) {
        return contentModel;
    }

    public boolean isEmpty() {
        return "EMPTY".equals(getAttribute("model"));
    }

    @JRubyMethod
    public IRubyObject prefix(ThreadContext context) {
        String enamePrefix = getPrefix(getAttribute("ename"));
        if (enamePrefix == null)
            return context.getRuntime().getNil();
        else
            return context.getRuntime().newString(enamePrefix);
    }

    /**
     * Returns the local part of the element name.
     */
    @Override
    @JRubyMethod
    public IRubyObject node_name(ThreadContext context) {
        String ename = getLocalPart(getAttribute("ename"));
        return context.getRuntime().newString(ename);
    }

    @Override
    @JRubyMethod(name = "node_name=")
    public IRubyObject node_name_set(ThreadContext context, IRubyObject name) {
        throw context.getRuntime()
            .newRuntimeError("cannot change name of DTD decl");
    }

    @Override
    @JRubyMethod
    public IRubyObject attribute_nodes(ThreadContext context) {
        return attrDecls;
    }

    @Override
    @JRubyMethod
    public IRubyObject attribute(ThreadContext context, IRubyObject name) {
        throw context.getRuntime()
            .newRuntimeError("attribute by name not implemented");
    }

    public void appendAttrDecl(XmlAttributeDecl decl) {
        attrDecls.append(decl);
    }

//     @JRubyMethod
//     public element_type(ThreadContext context) {
//     }
}
