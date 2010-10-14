package nokogiri.internals;

import java.util.ArrayList;
import java.util.List;

import nokogiri.XmlSyntaxError;

import org.apache.xerces.xni.parser.XMLErrorHandler;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.ErrorHandler;

/**
 * Super class of error handlers.
 * 
 * XMLErrorHandler is used by nokogiri.internals.HtmlDomParserContext since NekoHtml
 * uses this type of the error handler.
 * 
 * @author sergio
 */
public abstract class NokogiriErrorHandler implements ErrorHandler, XMLErrorHandler {
    protected List<Exception> errors;
    protected boolean noerror;
    protected boolean nowarning;

    public NokogiriErrorHandler(boolean noerror, boolean nowarning) {
        errors = new ArrayList<Exception>();
        this.noerror = noerror;
        this.nowarning = nowarning;
    }

    public List<Exception> getErrors() { return errors; }

    public List<IRubyObject> getErrorsReadyForRuby(ThreadContext context){
        Ruby ruby = context.getRuntime();
        List<IRubyObject> res = new ArrayList<IRubyObject>();
        for(int i = 0; i < errors.size(); i++) {
            res.add(new XmlSyntaxError(ruby, errors.get(i)));
        }
        return res;
    }

    protected boolean usesNekoHtml(String domain) {
        if ("http://cyberneko.org/html".equals(domain)) return true;
        else return false;
    }
}
