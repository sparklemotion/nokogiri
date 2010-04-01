/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri;

import nokogiri.internals.SaveContext;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 *
 * @author sergio
 */
public class XmlDocumentFragment extends XmlNode {

    public XmlDocumentFragment(Ruby ruby) {
        this(ruby, (RubyClass) ruby.getClassFromPath("Nokogiri::XML::DocumentFragment"));
    }

    public XmlDocumentFragment(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }

//    @JRubyMethod(name="new", meta = true)
//    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject doc) {
//        IRubyObject[] argc = new IRubyObject[1];
//        argc[0] = doc;
//        return rbNew(context, cls, argc);
//    }

    @JRubyMethod(name="new", meta = true, required=1, optional=1)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] argc) {
        
        if(argc.length < 1) {
            throw context.getRuntime().newArgumentError(argc.length, 1);
        }

        if(!(argc[0] instanceof XmlDocument)){
            throw context.getRuntime().newArgumentError("first parameter must be a Nokogiri::XML::Document instance");
        }

        XmlDocument doc = (XmlDocument) argc[0];

        XmlDocumentFragment fragment = new XmlDocumentFragment(context.getRuntime(),
                (RubyClass) cls);
        
        fragment.setDocument(doc);
        fragment.setNode(context.getRuntime(), doc.getDocument().createDocumentFragment());

        //TODO: Get namespace definitions from doc.

        RuntimeHelpers.invoke(context, fragment, "initialize", argc);

        return fragment;
    }

    //@Override
    public void add_child(ThreadContext context, XmlNode child) {
        // Some magic for DocumentFragment

        Ruby ruby = context.getRuntime();
        XmlNodeSet children = (XmlNodeSet) child.children(context);

        long length = children.length();

        RubyArray childrenArray = children.convertToArray();

        if(length != 0) {
            for(int i = 0; i < length; i++) {
                XmlNode item = (XmlNode) ((XmlNode) childrenArray.aref(ruby.newFixnum(i))).dup(context);
                add_child(context, item);
            }
        }
    }

    @Override
    public void relink_namespace(ThreadContext context) {
        ((XmlNodeSet) children(context)).relink_namespace(context);
    }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        saveNodeListContent(context, (XmlNodeSet) children(context), ctx);
    }

}
