/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2011:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com]
 * * {Sergio Arbeo}[http://www.serabe.com]
 * * {Patrick Mahoney}[http://polycrystal.org]
 * * {Yoko Harada}[http://yokolet.blogspot.com]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;

import nokogiri.internals.NokogiriXsltErrorListener;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;

/**
 * Class for Nokogiri::XSLT::Stylesheet
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name="Nokogiri::XSLT::Stylesheet")
public class XsltStylesheet extends RubyObject {
    private static Map<String, Object> registry = new HashMap<String, Object>();
    private static TransformerFactory factory = null;
    private Templates sheet;

    public static Map<String, Object> getRegistry() {
        return registry;
    }

    public XsltStylesheet(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    private void addParametersToTransformer(ThreadContext context, Transformer transf, IRubyObject parameters) {
        Ruby ruby = context.getRuntime();
        RubyArray params = parameters.convertToArray();
        int limit = params.getLength();
        if(limit % 2 == 1) limit--;

        for(int i = 0; i < limit; i+=2) {
            String name = params.aref(ruby.newFixnum(i)).asJavaString();
            String value = params.aref(ruby.newFixnum(i+1)).asJavaString();
            transf.setParameter(name, unparseValue(value));
        }
    }
    
    private Pattern p = Pattern.compile("'.{1,}'");

    private String unparseValue(String orig) {
        Matcher m = p.matcher(orig);
        if ((orig.startsWith("\"") && orig.endsWith("\"")) || m.matches()) {
            orig = orig.substring(1, orig.length()-1);
        }

        return orig;
    }

    @JRubyMethod(meta = true)
    public static IRubyObject parse_stylesheet_doc(ThreadContext context, IRubyObject cls, IRubyObject document) {
        
        Ruby ruby = context.getRuntime();

        if(!(document instanceof XmlDocument)) {
            throw ruby.newArgumentError("doc must be a Nokogiri::XML::Document instance");
        }

        XmlDocument xmlDoc = (XmlDocument) document;

        RubyArray errors = (RubyArray) xmlDoc.getInstanceVariable("@errors");

        if(!errors.isEmpty()) {
            throw ruby.newRuntimeError(errors.first().asJavaString());
        }
        
        Document doc = ((XmlDocument) xmlDoc.dup_implementation(context, true)).getDocument();

        XsltStylesheet xslt = new XsltStylesheet(ruby, (RubyClass) cls);

        try {
            if (factory == null) factory = TransformerFactory.newInstance();
            xslt.sheet = factory.newTemplates(new DOMSource(doc));
        } catch (TransformerConfigurationException ex) {
            ruby.newRuntimeError("could not parse xslt stylesheet");
        }

        return xslt;
    }

    @JRubyMethod
    public IRubyObject serialize(ThreadContext context, IRubyObject doc) {
        return RuntimeHelpers.invoke(context,
                RuntimeHelpers.invoke(context, doc, "root"),
                "to_s");
    }

    @JRubyMethod(rest = true, required=1, optional=2)
    public IRubyObject transform(ThreadContext context, IRubyObject[] args) {
        Ruby runtime = context.getRuntime();

        DOMSource docSource = new DOMSource(((XmlDocument) args[0]).getDocument());
        DOMResult result = new DOMResult();

        NokogiriXsltErrorListener elistener = new NokogiriXsltErrorListener();
        try{
            Transformer transf = this.sheet.newTransformer();
            transf.setErrorListener(elistener);
            if(args.length > 1) {
                addParametersToTransformer(context, transf, args[1]);
            }
            transf.transform(docSource, result);
        } catch(TransformerConfigurationException ex) {
            // processes later
        } catch(TransformerException ex) {
            // processes later
        }

        switch (elistener.getErrorType()) {
            case ERROR:
            case FATAL:
                throw runtime.newRuntimeError(elistener.getErrorMessage());
            case WARNING:
            default:
                // no-op
        }
        
        if ("html".equals(result.getNode().getFirstChild().getNodeName())) {
            HtmlDocument htmlDocument = (HtmlDocument) getNokogiriClass(runtime, "Nokogiri::HTML::Document").allocate();
            htmlDocument.setNode(context, (Document) result.getNode());
            return htmlDocument;
        } else {
            XmlDocument xmlDocument = (XmlDocument) NokogiriService.XML_DOCUMENT_ALLOCATOR.allocate(runtime, getNokogiriClass(runtime, "Nokogiri::XML::Document"));
            xmlDocument.setNode(context, (Document) result.getNode());
            return xmlDocument;
        }
    }
    
    @JRubyMethod(name = {"registr", "register"}, meta = true)
    public static IRubyObject register(ThreadContext context, IRubyObject cls, IRubyObject uri, IRubyObject receiver) {
        throw context.getRuntime().newNotImplementedError("Nokogiri::XSLT.register method is not implemented");
        /* When API conflict is solved, this method should be below:
        // ThreadContext is used while executing xslt extension function
        registry.put("context", context);
        registry.put("receiver", receiver);
        return context.getRuntime().getNil();
        */
    }
}
