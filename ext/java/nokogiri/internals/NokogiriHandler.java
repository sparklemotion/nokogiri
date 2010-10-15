package nokogiri.internals;

import java.util.Arrays;
import java.util.LinkedList;
import static nokogiri.internals.NokogiriHelpers.getLocalPart;
import static nokogiri.internals.NokogiriHelpers.getPrefix;
import static nokogiri.internals.NokogiriHelpers.isNamespace;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import java.util.logging.Logger;

import nokogiri.XmlSyntaxError;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.ext.DefaultHandler2;

/**
 *
 * @author sergio
 */
public class NokogiriHandler extends DefaultHandler2
    implements XmlDeclHandler {

    private static Logger LOGGER = Logger.getLogger(NokogiriHandler.class.getName());

    boolean inCDATA = false;

    private Ruby ruby;
    private RubyClass attrClass;
    private IRubyObject object;
    private boolean namespaceDefined = false;

    /**
     * Stores parse errors with the most-recent error last.
     *
     * TODO: should these be stored in the document 'errors' array?
     * Currently only string messages are stored there.
     */
    private LinkedList<XmlSyntaxError> errors =
        new LinkedList<XmlSyntaxError>();

    public NokogiriHandler(Ruby ruby, IRubyObject object) {
        this.ruby = ruby;
        this.attrClass = (RubyClass) ruby.getClassFromPath(
            "Nokogiri::XML::SAX::Parser::Attribute");
        this.object = object;
    }

    @Override
    public void startDocument() throws SAXException {
        call("start_document");
    }

    public void xmlDecl(String version, String encoding, String standalone) {
        call("xmldecl", stringOrNil(ruby, version),
             stringOrNil(ruby, encoding),
             stringOrNil(ruby, standalone));
    }

    @Override
    public void endDocument() throws SAXException {
        call("end_document");
    }

    /*
     * This has to call either "start_element" or
     * "start_element_namespace" depending on whether there are any
     * namespace attributes.
     *
     * Attributes that define namespaces are passed in a separate
     * array of of <code>[:prefix, :uri]</code> arrays and are not
     * passed with the other attributes.
     */
    @Override
    public void startElement(String uri, String localName, String qName,
                             Attributes attrs) throws SAXException {
        // for attributes other than namespace attrs
        RubyArray rubyAttr = RubyArray.newArray(ruby);
        // for namespace defining attributes
        RubyArray rubyNSAttr = RubyArray.newArray(ruby);

        ThreadContext context = ruby.getCurrentContext();
        boolean fromFragmentHandler = false; // isFromFragmentHandler();
        
        for (int i = 0; i < attrs.getLength(); i++) {
            String u = attrs.getURI(i);
            String qn = attrs.getQName(i);
            String ln = attrs.getLocalName(i);
            String val = attrs.getValue(i);
            String pre;

            pre = getPrefix(qn);
            if (ln == null || ln.equals("")) ln = getLocalPart(qn);

            if (isNamespace(qn) && !fromFragmentHandler) {
                // I haven't figured the reason out yet, but, in somewhere,
                // namespace is converted to array in array in array and cause
                // TypeError at line 45 in fragment_handler.rb
                RubyArray ns = RubyArray.newArray(ruby, 2);
                if (ln.equals("xmlns")) ln = null;
                ns.add(stringOrNil(ruby, ln));
                ns.add(ruby.newString(val));
                rubyNSAttr.add(ns);
            } else {
                IRubyObject[] args = new IRubyObject[4];
                args[0] = stringOrNil(ruby, ln);
                args[1] = stringOrNil(ruby, pre);
                args[2] = stringOrNil(ruby, u);
                args[3] = stringOrNil(ruby, val);

                IRubyObject attr =
                    RuntimeHelpers.invoke(context, attrClass, "new", args);
                rubyAttr.add(attr);
            }
        }

        if (localName == null || localName.equals(""))
            localName = getLocalPart(qName);
        call("start_element_namespace",
             stringOrNil(ruby, localName),
             rubyAttr,
             stringOrNil(ruby, getPrefix(qName)),
             stringOrNil(ruby, uri),
             rubyNSAttr);
    }
    
    private boolean isFromFragmentHandler() {
        if (object != null && object instanceof RubyObject) {
            RubyObject rubyObj = (RubyObject)object;
            IRubyObject document = rubyObj.getInstanceVariable("@document");
            if (document != null) {
                String name = document.getMetaClass().getName();
                if ("Nokogiri::XML::FragmentHandler".equals(name)) {
                    return true;
                }
            }
        }
        return false;
    }

    @Override
    public void endElement(String uri, String localName, String qName) throws SAXException {
        call("end_element_namespace",
             stringOrNil(ruby, localName),
             stringOrNil(ruby, getPrefix(qName)),
             stringOrNil(ruby, uri));
    }

    @Override
    public void characters(char[] ch, int start, int length) throws SAXException {
        String target = inCDATA ? "cdata_block" : "characters";
        call(target, ruby.newString(new String(ch, start, length)));
    }

    @Override
    public void comment(char[] ch, int start, int length) throws SAXException {
        call("comment", ruby.newString(new String(ch, start, length)));
    }

    @Override
    public void startCDATA() throws SAXException {
        inCDATA = true;
    }

    @Override
    public void endCDATA() throws SAXException {
        inCDATA = false;
    }

    @Override
    public void error(SAXParseException saxpe) {
        addError(XmlSyntaxError.createError(ruby, saxpe));
        call("error", ruby.newString(saxpe.getMessage()));
    }

    @Override
    public void fatalError(SAXParseException saxpe) throws SAXException
    {
        addError(XmlSyntaxError.createFatalError(ruby, saxpe));
        call("error", ruby.newString(saxpe.getMessage()));
    }

    @Override
    public void warning(SAXParseException saxpe) {
        //System.out.println("warning: " + saxpe);
        call("warning", ruby.newString(saxpe.getMessage()));
    }

    protected synchronized void addError(XmlSyntaxError e) {
        errors.add(e);
    }

    public synchronized int getErrorCount() {
        return errors.size();
    }

    public synchronized IRubyObject getLastError() {
        return errors.getLast();
    }

    private void call(String methodName) {
        ThreadContext context = ruby.getCurrentContext();
        RuntimeHelpers.invoke(context, document(context), methodName);
    }

    private void call(String methodName, IRubyObject argument) {
        ThreadContext context = ruby.getCurrentContext();
        RuntimeHelpers.invoke(context, document(context), methodName, argument);
    }

    private void call(String methodName, IRubyObject arg1, IRubyObject arg2) {
        ThreadContext context = ruby.getCurrentContext();
        RuntimeHelpers.invoke(context, document(context), methodName, arg1, arg2);
    }

    private void call(String methodName, IRubyObject arg1, IRubyObject arg2,
                      IRubyObject arg3) {
        ThreadContext context = ruby.getCurrentContext();
        RuntimeHelpers.invoke(context, document(context), methodName,
                              arg1, arg2, arg3);
    }

    private void call(String methodName,
                      IRubyObject arg0,
                      IRubyObject arg1,
                      IRubyObject arg2,
                      IRubyObject arg3,
                      IRubyObject arg4) {
        IRubyObject[] args = new IRubyObject[5];
        args[0] = arg0;
        args[1] = arg1;
        args[2] = arg2;
        args[3] = arg3;
        args[4] = arg4;
        ThreadContext context = ruby.getCurrentContext();
        RuntimeHelpers.invoke(context, document(context), methodName, args);
    }

    private IRubyObject document(ThreadContext context){
        return RuntimeHelpers.invoke(context, this.object, "document");
    }

}
