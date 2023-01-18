package nokogiri.internals;

import nokogiri.internals.*;

import org.jruby.Ruby;
import org.jruby.RubyClass;

public abstract class DomParserContext<TParser> extends ParserContext
{
  private static final long serialVersionUID = 1L;

  public
  DomParserContext(Ruby ruby)
  {
    super(ruby, ruby.getObject()); // class 'Object' because this class hierarchy isn't exposed to Ruby
  }
}
