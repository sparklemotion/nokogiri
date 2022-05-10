package nokogiri;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.sourceforge.htmlunit.cyberneko.HTMLElements;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Class for Nokogiri::HTML4::ElementDescription.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
@JRubyClass(name = "Nokogiri::HTML4::ElementDescription")
public class Html4ElementDescription extends RubyObject
{
  private static final long serialVersionUID = 1L;
  private static final HTMLElements htmlElements_ = new HTMLElements();

  /**
   * Stores memoized hash of element -> list of valid subelements.
   */
  static protected Map<Short, List<String>> subElements;
  static
  {
    Map<Short, List<String>> _subElements =
      new HashMap<Short, List<String>>();
    subElements = Collections.synchronizedMap(_subElements);
  }

  protected HTMLElements.Element element;

  public
  Html4ElementDescription(Ruby runtime, RubyClass rubyClass)
  {
    super(runtime, rubyClass);
  }

  /**
   * Lookup the list of sub elements of <code>code</code>.  If not
   * already stored, iterate through all elements to find valid
   * subelements; save this list and return it.
   */
  protected static List<String>
  findSubElements(HTMLElements.Element elem)
  {
    List<String> subs = subElements.get(elem.code);

    if (subs == null) {
      subs = new ArrayList<String>();

      /*
       * A bit of a hack.  NekoHtml source code shows that
       * UNKNOWN is the highest value element.  We cannot access
       * the list of elements directly because it's protected.
       */
      for (short c = 0; c < HTMLElements.UNKNOWN; c++) {
        HTMLElements.Element maybe_sub = htmlElements_.getElement(c);
        if (maybe_sub != null && maybe_sub.isParent(elem)) {
          subs.add(maybe_sub.name);
        }
      }

      subElements.put(elem.code, subs);
    }

    return subs;
  }

  @JRubyMethod(name = "[]", meta = true)
  public static IRubyObject
  get(ThreadContext context,
      IRubyObject klazz, IRubyObject name)
  {

    // nekohtml will return an element even for invalid names, which breaks `test_fetch_nonexistent'
    // see getElement() in HTMLElements.java
    HTMLElements.Element elem = htmlElements_.getElement(name.asJavaString(), htmlElements_.NO_SUCH_ELEMENT);
    if (elem == htmlElements_.NO_SUCH_ELEMENT) {
      return context.nil;
    }

    Html4ElementDescription desc =
      new Html4ElementDescription(context.getRuntime(), (RubyClass)klazz);
    desc.element = elem;
    return desc;
  }

  @JRubyMethod()
  public IRubyObject
  name(ThreadContext context)
  {
    return context.getRuntime().newString(element.name.toLowerCase());
  }

  @JRubyMethod(name = "inline?")
  public IRubyObject
  inline_eh(ThreadContext context)
  {
    return context.getRuntime().newBoolean(element.isInline());
  }

  @JRubyMethod(name = "empty?")
  public IRubyObject
  empty_eh(ThreadContext context)
  {
    return context.getRuntime().newBoolean(element.isEmpty());
  }

  @JRubyMethod()
  public IRubyObject
  sub_elements(ThreadContext context)
  {
    Ruby ruby = context.getRuntime();
    List<String> subs = findSubElements(element);
    IRubyObject[] ary = new IRubyObject[subs.size()];
    for (int i = 0; i < subs.size(); ++i) {
      ary[i] = ruby.newString(subs.get(i));
    }

    return ruby.newArray(ary);
  }

}
