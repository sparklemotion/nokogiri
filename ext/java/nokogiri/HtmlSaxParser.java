package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;

public class HtmlSaxParser extends RubyObject {
    public HtmlSaxParser(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    @JRubyMethod(visibility = Visibility.PRIVATE)
    public static IRubyObject native_parse_memory(ThreadContext context, IRubyObject self, IRubyObject data, IRubyObject encoding) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod(visibility = Visibility.PRIVATE)
    public static IRubyObject native_parse_file(ThreadContext context, IRubyObject self, IRubyObject data, IRubyObject encoding) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }
}
