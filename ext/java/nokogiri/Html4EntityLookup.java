package nokogiri;

import static org.jruby.runtime.Helpers.invoke;

import net.sourceforge.htmlunit.cyberneko.HTMLEntitiesParser;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Class for Nokogiri::HTML4::EntityLookup.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
@JRubyClass(name = "Nokogiri::HTML4::EntityLookup")
public class Html4EntityLookup extends RubyObject
{
  private static final long serialVersionUID = 1L;

  public
  Html4EntityLookup(Ruby runtime, RubyClass rubyClass)
  {
    super(runtime, rubyClass);
  }

  /**
   * Looks up an HTML entity <code>key</code>.
   *
   * The description is a bit lacking.
   */
  @JRubyMethod()
  public IRubyObject
  get(ThreadContext context, IRubyObject key)
  {
    Ruby ruby = context.getRuntime();
    String name = key.toString();

    HTMLEntitiesParser parser = new HTMLEntitiesParser();
    for (int j = 0 ; j < name.length() ; j++) {
      if (!parser.parse(name.charAt(j))) {
        break;
      }
    }
    String match = parser.getMatch();

    if (match == null) { return ruby.getNil(); }

    int val = match.charAt(0);

    IRubyObject edClass =
      ruby.getClassFromPath("Nokogiri::HTML4::EntityDescription");
    IRubyObject edObj = invoke(context, edClass, "new",
                               ruby.newFixnum(val), ruby.newString(name),
                               ruby.newString(name + " entity"));

    return edObj;
  }

}
