package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 * DTD entity declaration.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
public class XmlEntityDecl extends XmlNode {
    public static final int INTERNAL_GENERAL = 1;
    public static final int EXTERNAL_GENERAL_PARSED = 2;
    public static final int EXTERNAL_GENERAL_UNPARSED  = 3;
    public static final int INTERNAL_PARAMETER = 4;
    public static final int EXTERNAL_PARAMETER = 5;
    public static final int INTERNAL_PREDEFINED = 6;
    

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
        if (!klass.isConstantDefined("INTERNAL_GENERAL")) klass.defineConstant("INTERNAL_GENERAL", RubyFixnum.newFixnum(ruby, INTERNAL_GENERAL));
        if (!klass.isConstantDefined("EXTERNAL_GENERAL_PARSED")) klass.defineConstant("EXTERNAL_GENERAL_PARSED", RubyFixnum.newFixnum(ruby, EXTERNAL_GENERAL_PARSED));
        if (!klass.isConstantDefined("EXTERNAL_GENERAL_UNPARSED")) klass.defineConstant("EXTERNAL_GENERAL_UNPARSED", RubyFixnum.newFixnum(ruby, EXTERNAL_GENERAL_UNPARSED));
        if (!klass.isConstantDefined("INTERNAL_PARAMETER")) klass.defineConstant("INTERNAL_PARAMETER", RubyFixnum.newFixnum(ruby, INTERNAL_PARAMETER));
        if (!klass.isConstantDefined("EXTERNAL_PARAMETER")) klass.defineConstant("EXTERNAL_PARAMETER", RubyFixnum.newFixnum(ruby, EXTERNAL_PARAMETER));
        if (!klass.isConstantDefined("INTERNAL_PREDEFINED")) klass.defineConstant("INTERNAL_PREDEFINED", RubyFixnum.newFixnum(ruby, INTERNAL_PREDEFINED));
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

    @JRubyMethod
    public IRubyObject entity_type(ThreadContext context) {
        return context.getRuntime().newFixnum(node.getNodeType());
    }
}
