package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

/**
 * DTD entity declaration.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
public class XmlEntityDecl extends XmlNode {

    public static RubyClass getRubyClass(Ruby ruby) {
        return (RubyClass)ruby.getClassFromPath("Nokogiri::XML::EntityDecl");
    }

    public XmlEntityDecl(Ruby ruby, RubyClass klass) {
        super(ruby, klass);
        throw ruby.newRuntimeError("node required");
    }

    /**
     * Initialize based on an entityDecl node from a NekoDTD parsed
     * DTD.
     */
    public XmlEntityDecl(Ruby ruby, RubyClass klass, Node entDeclNode) {
        super(ruby, klass, entDeclNode);
    }

    public static IRubyObject create(ThreadContext context, Node entDeclNode) {
        XmlEntityDecl self =
            new XmlEntityDecl(context.getRuntime(),
                              getRubyClass(context.getRuntime()),
                              entDeclNode);
        return self;
    }

    /**
     * Returns the local part of the element name.
     */
    @Override
    @JRubyMethod
    public IRubyObject node_name(ThreadContext context) {
        return getAttribute(context, "name");
    }

    @Override
    @JRubyMethod(name = "node_name=")
    public IRubyObject node_name_set(ThreadContext context, IRubyObject name) {
        throw context.getRuntime()
            .newRuntimeError("cannot change name of DTD decl");
    }

    @JRubyMethod
    public IRubyObject content(ThreadContext context) {
        return getAttribute(context, "value");
    }

    // TODO: what is content vs. original_content?
    @JRubyMethod
    public IRubyObject original_content(ThreadContext context) {
        return getAttribute(context, "value");
    }

    @JRubyMethod
    public IRubyObject system_id(ThreadContext context) {
        return getAttribute(context, "sysid");
    }

    @JRubyMethod
    public IRubyObject external_id(ThreadContext context) {
        return getAttribute(context, "pubid");
    }
}
