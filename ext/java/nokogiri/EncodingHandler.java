package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import java.util.HashMap;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Stub class to satisfy unit tests.  I'm not sure where this class is
 * meant to be used. As coded it won't really interact with any other
 * classes and will have no effect on character encodings reported by
 * documents being parsed.
 *
 * @author Patrick Mahoney <pat@polycrstal.org>
 */
@JRubyClass(name = "Nokogiri::EncodingHandler")
public class EncodingHandler extends RubyObject
{
  protected static HashMap<String, String> map = new HashMap<String, String>();
  static
  {
    addInitial();
  }

  protected String name;

  protected static void
  addInitial()
  {
    map.put("UTF-8", "UTF-8");
  }

  public
  EncodingHandler(Ruby ruby, RubyClass klass, String value)
  {
    super(ruby, klass);
    name = value;
  }

  @JRubyMethod(name = "[]", meta = true)
  public static IRubyObject
  get(ThreadContext context,
      IRubyObject _klass,
      IRubyObject keyObj)
  {
    Ruby ruby = context.getRuntime();
    String key = keyObj.toString();
    String value = map.get(key);
    if (value == null) {
      return ruby.getNil();
    }

    return new EncodingHandler(
             ruby,
             getNokogiriClass(ruby, "Nokogiri::EncodingHandler"),
             value);
  }

  @JRubyMethod(meta = true)
  public static IRubyObject
  delete (ThreadContext context,
          IRubyObject _klass,
          IRubyObject keyObj)
  {
    String key = keyObj.toString();
    String value = map.remove(key);
    if (value == null) {
      return context.getRuntime().getNil();
    }
    return context.getRuntime().newString(value);
  }

  @JRubyMethod(name = "clear_aliases!", meta = true)
  public static IRubyObject
  clear_aliases(ThreadContext context,
                IRubyObject _klass)
  {
    map.clear();
    addInitial();
    return context.getRuntime().getNil();
  }

  @JRubyMethod(meta = true)
  public static IRubyObject
  alias(ThreadContext context,
        IRubyObject _klass,
        IRubyObject orig,
        IRubyObject alias)
  {
    String value = map.get(orig.toString());
    if (value != null) {
      map.put(alias.toString(), value);
    }

    return context.getRuntime().getNil();
  }

  @JRubyMethod
  public IRubyObject
  name(ThreadContext context)
  {
    return context.getRuntime().newString(name);
  }
}
