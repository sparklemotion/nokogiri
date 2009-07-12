/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri.internals;

import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 *
 * @author sergio
 */
public class XmlCdataMethods extends XmlNodeMethods {

    @Override
    public IRubyObject getNullContent(ThreadContext context) {
        return context.getRuntime().getNil();
    }
}
