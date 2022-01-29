package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.getLocalPart;
import static nokogiri.internals.NokogiriHelpers.getPrefix;
import static nokogiri.internals.NokogiriHelpers.isNamespace;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.Set;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.Attributes;
import org.xml.sax.Locator;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.ext.DefaultHandler2;

import nokogiri.XmlSyntaxError;

/**
 * A handler for SAX parsing.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriHandler extends DefaultHandler2 implements XmlDeclHandler
{

  StringBuilder charactersBuilder;
  private final Ruby runtime;
  private final RubyClass attrClass;
  private final IRubyObject object;
  private NokogiriErrorHandler errorHandler;

  private Locator locator;
  private boolean needEmptyAttrCheck;

  public
  NokogiriHandler(Ruby runtime, IRubyObject object, NokogiriErrorHandler errorHandler)
  {
    assert object != null;
    this.runtime = runtime;
    this.attrClass = (RubyClass) runtime.getClassFromPath("Nokogiri::XML::SAX::Parser::Attribute");
    this.object = object;
    this.errorHandler = errorHandler;
    charactersBuilder = new StringBuilder();
    String objectName = object.getMetaClass().getName();
    if ("Nokogiri::HTML4::SAX::Parser".equals(objectName)) { needEmptyAttrCheck = true; }
  }

  @Override
  public void
  skippedEntity(String skippedEntity)
  {
    call("error", runtime.newString("Entity '" + skippedEntity + "' not defined\n"));
  }

  @Override
  public void
  setDocumentLocator(Locator locator)
  {
    this.locator = locator;
  }

  @Override
  public void
  startDocument()
  {
    call("start_document");
  }

  @Override
  public void
  xmlDecl(String version, String encoding, String standalone)
  {
    call("xmldecl", stringOrNil(runtime, version), stringOrNil(runtime, encoding), stringOrNil(runtime, standalone));
  }

  @Override
  public void
  endDocument()
  {
    populateCharacters();
    call("end_document");
  }

  @Override
  public void
  processingInstruction(String target, String data)
  {
    call("processing_instruction", runtime.newString(target), runtime.newString(data));
  }

  /*
   * This calls "start_element_namespace".
   *
   * Attributes that define namespaces are passed in a separate
   * array of <code>[:prefix, :uri]</code> arrays and are not
   * passed with the other attributes.
   */
  @Override
  public void
  startElement(String uri, String localName, String qName, Attributes attrs) throws SAXException
  {
    final Ruby runtime = this.runtime;
    final ThreadContext context = runtime.getCurrentContext();

    // for attributes other than namespace attrs
    RubyArray<?> rubyAttr = RubyArray.newArray(runtime);
    // for namespace defining attributes
    RubyArray<?> rubyNSAttr = RubyArray.newArray(runtime);

    boolean fromFragmentHandler = false; // isFromFragmentHandler();

    for (int i = 0; i < attrs.getLength(); i++) {
      String u = attrs.getURI(i);
      String qn = attrs.getQName(i);
      String ln = attrs.getLocalName(i);
      String val = attrs.getValue(i);
      String pre;

      pre = getPrefix(qn);
      if (ln == null || ln.isEmpty()) { ln = getLocalPart(qn); }

      if (isNamespace(qn) && !fromFragmentHandler) {
        // I haven't figured the reason out yet, but, in somewhere,
        // namespace is converted to array in array and cause
        // TypeError at line 45 in fragment_handler.rb
        if (ln.equals("xmlns")) { ln = null; }
        rubyNSAttr.append(runtime.newArray(stringOrNil(runtime, ln), runtime.newString(val)));
      } else {
        IRubyObject[] args = null;
        if (needEmptyAttrCheck) {
          if (isEmptyAttr(ln)) {
            args = new IRubyObject[] {
              stringOrNil(runtime, ln),
              stringOrNil(runtime, pre),
              stringOrNil(runtime, u)
            };
          }
        }
        if (args == null) {
          args = new IRubyObject[] {
            stringOrNil(runtime, ln),
            stringOrNil(runtime, pre),
            stringOrNil(runtime, u),
            stringOrNil(runtime, val)
          };
        }

        rubyAttr.append(Helpers.invoke(context, attrClass, "new", args));
      }
    }

    if (localName == null || localName.isEmpty()) { localName = getLocalPart(qName); }
    populateCharacters();
    call("start_element_namespace",
         stringOrNil(runtime, localName),
         rubyAttr,
         stringOrNil(runtime, getPrefix(qName)),
         stringOrNil(runtime, uri),
         rubyNSAttr);
  }

  static final Set<String> EMPTY_ATTRS;
  static
  {
    final String[] emptyAttrs = {
      "checked", "compact", "declare", "defer", "disabled", "ismap", "multiple",
      "noresize", "nohref", "noshade", "nowrap", "readonly", "selected"
    };
    EMPTY_ATTRS = new HashSet<String>(Arrays.asList(emptyAttrs));
  }

  private static boolean
  isEmptyAttr(String name)
  {
    return EMPTY_ATTRS.contains(name);
  }

  public final Integer
  getLine()   // -1 if none is available
  {
    final int line = locator.getLineNumber();
    return line == -1 ? null : line;
  }

  public final Integer
  getColumn()   // -1 if none is available
  {
    final int column = locator.getColumnNumber();
    return column == -1 ? null : column - 1;
  }

  @Override
  public void
  endElement(String uri, String localName, String qName)
  {
    populateCharacters();
    call("end_element_namespace",
         stringOrNil(runtime, localName),
         stringOrNil(runtime, getPrefix(qName)),
         stringOrNil(runtime, uri));
  }

  @Override
  public void
  characters(char[] ch, int start, int length)
  {
    charactersBuilder.append(ch, start, length);
  }

  @Override
  public void
  comment(char[] ch, int start, int length)
  {
    populateCharacters();
    call("comment", runtime.newString(new String(ch, start, length)));
  }

  @Override
  public void
  startCDATA()
  {
    populateCharacters();
  }

  @Override
  public void
  endCDATA()
  {
    call("cdata_block", runtime.newString(charactersBuilder.toString()));
    charactersBuilder.setLength(0);
  }

  void
  handleError(SAXParseException ex)
  {
    try {
      final String msg = ex.getMessage();
      call("error", runtime.newString(msg == null ? "" : msg));
      errorHandler.addError(ex);
    } catch (RaiseException e) {
      errorHandler.addError(e);
      throw e;
    }
  }

  @Override
  public void
  error(SAXParseException ex)
  {
    handleError(ex);
  }

  @Override
  public void
  fatalError(SAXParseException ex)
  {
    handleError(ex);
  }

  @Override
  public void
  warning(SAXParseException ex)
  {
    final String msg = ex.getMessage();
    call("warning", runtime.newString(msg == null ? "" : msg));
  }

  public synchronized int
  getErrorCount()
  {
    return errorHandler.getErrors().size();
  }

  private void
  call(String methodName)
  {
    ThreadContext context = runtime.getCurrentContext();
    Helpers.invoke(context, document(context), methodName);
  }

  private void
  call(String methodName, IRubyObject argument)
  {
    ThreadContext context = runtime.getCurrentContext();
    Helpers.invoke(context, document(context), methodName, argument);
  }

  private void
  call(String methodName, IRubyObject arg1, IRubyObject arg2)
  {
    ThreadContext context = runtime.getCurrentContext();
    Helpers.invoke(context, document(context), methodName, arg1, arg2);
  }

  private void
  call(String methodName, IRubyObject arg1, IRubyObject arg2, IRubyObject arg3)
  {
    ThreadContext context = runtime.getCurrentContext();
    Helpers.invoke(context, document(context), methodName, arg1, arg2, arg3);
  }

  private void
  call(String methodName,
       IRubyObject arg0,
       IRubyObject arg1,
       IRubyObject arg2,
       IRubyObject arg3,
       IRubyObject arg4)
  {
    ThreadContext context = runtime.getCurrentContext();
    Helpers.invoke(context, document(context), methodName, arg0, arg1, arg2, arg3, arg4);
  }

  private IRubyObject
  document(ThreadContext context)
  {
    return object.getInstanceVariables().getInstanceVariable("@document");
  }

  protected void
  populateCharacters()
  {
    if (charactersBuilder.length() > 0) {
      call("characters", runtime.newString(charactersBuilder.toString()));
      charactersBuilder.setLength(0);
    }
  }
}
