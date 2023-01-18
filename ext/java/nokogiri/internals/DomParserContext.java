package nokogiri.internals;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.runtime.builtin.IRubyObject;

import nokogiri.internals.ParserContext;
import nokogiri.internals.ParserContext.Options;

public abstract class DomParserContext<TParser> extends ParserContext
{
  private static final long serialVersionUID = 1L;

  protected ParserContext.Options options;
  protected TParser parser;

  public
  DomParserContext(Ruby ruby, IRubyObject parserOptions)
  {
    super(ruby, ruby.getObject()); // class 'Object' because this class hierarchy isn't exposed to Ruby
    options = new ParserContext.Options(RubyFixnum.fix2long(parserOptions));
  }
}
