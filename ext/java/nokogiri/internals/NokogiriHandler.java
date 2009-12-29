package nokogiri.internals;

import org.jruby.Ruby;
import org.jruby.RubyArray;
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
public class NokogiriHandler extends DefaultHandler2{
    boolean inCDATA = false;

    private Ruby ruby;
    private IRubyObject object;

    public NokogiriHandler(Ruby ruby, IRubyObject object) {
        this.ruby = ruby;
        this.object = object;
    }

    @Override
    public void startDocument() throws SAXException {
        call("start_document");
    }

    @Override
    public void endDocument() throws SAXException {
        call("end_document");
    }

    @Override
    public void startElement(String uri, String localName, String qName, Attributes attr) throws SAXException {
        RubyArray attrs = RubyArray.newArray(ruby, attr.getLength());
        for (int i = 0; i < attr.getLength(); i++) {
            attrs.append(ruby.newString(attr.getQName(i)));
            attrs.append(ruby.newString(attr.getValue(i)));
        }
        call("start_element", ruby.newString(qName), attrs);
    }

    @Override
    public void endElement(String uri, String localName, String qName) throws SAXException {
        call("end_element", ruby.newString(qName));
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
        call("error", ruby.newString(saxpe.getMessage()));
    }

    @Override
    public void warning(SAXParseException saxpe) {
        call("warning", ruby.newString(saxpe.getMessage()));
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

    private IRubyObject document(ThreadContext context){
		return RuntimeHelpers.invoke(context, this.object, "document");
    }
}
