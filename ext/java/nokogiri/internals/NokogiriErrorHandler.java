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
 *
 * @author sergio
 */
public abstract class NokogiriErrorHandler
    implements ErrorHandler, XMLErrorHandler {

    protected List<Exception> errors;

    public NokogiriErrorHandler() {
        this.errors = new ArrayList<Exception>();
    }

    void addError(Exception e) {
        errors.add(e);
    }

    public List<Exception> getErrors() { return this.errors; }

    public List<IRubyObject> getErrorsReadyForRuby(ThreadContext context){
        Ruby ruby = context.getRuntime();
        List<IRubyObject> res = new ArrayList<IRubyObject>();
        for(int i = 0; i < this.errors.size(); i++) {
            res.add(new XmlSyntaxError(ruby, this.errors.get(i)));
        }
        return res;
    }

}
