package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getCachedNodeOrCreate;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.SaveContextVisitor;

import org.apache.xerces.dom.CoreDocumentImpl;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::EntityReference
 *
 * @author sergio
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::EntityReference", parent = "Nokogiri::XML::Node")
public class XmlEntityReference extends XmlNode
{
  private static final long serialVersionUID = 1L;

  public
  XmlEntityReference(Ruby ruby, RubyClass klazz)
  {
    super(ruby, klazz);
  }

  public
  XmlEntityReference(Ruby ruby, RubyClass klass, Node node)
  {
    super(ruby, klass, node);
  }

  protected void
  init(ThreadContext context, IRubyObject[] args)
  {
    if (args.length < 2) {
      throw context.runtime.newArgumentError(args.length, 2);
    }

    IRubyObject doc = args[0];
    IRubyObject name = args[1];

    Document document = ((XmlNode) doc).getOwnerDocument();
    // FIXME: disable error checking as a workaround for #719. this depends on the internals of Xerces.
    CoreDocumentImpl internalDocument = (CoreDocumentImpl) document;
    boolean oldErrorChecking = internalDocument.getErrorChecking();
    internalDocument.setErrorChecking(false);
    Node node = document.createEntityReference(rubyStringToString(name));
    internalDocument.setErrorChecking(oldErrorChecking);
    setNode(context.runtime, node);
  }

  @Override
  public void
  accept(ThreadContext context, SaveContextVisitor visitor)
  {
    //
    // Note that when noEnt is set, we call setFeature(FEATURE_NOT_EXPAND_ENTITY, false) in
    // XmlDomParserContext.
    //
    // See https://xerces.apache.org/xerces-j/features.html section on `create-entity-ref-nodes`
    //
    // When set to true (the default), then EntityReference nodes are present in the DOM tree, and
    // its children represent the replacement text. When set to false, then the EntityReference is
    // not present in the tree, and instead the replacement text nodes are present.
    //
    // So: if we are here, then noEnt must be true, and we should just serialize the EntityReference
    // and not worry about the replacement text. When noEnt is false, we would never this and
    // instead would be serializing the replacement text.
    //
    // https://github.com/sparklemotion/nokogiri/issues/3270
    //
    visitor.enter(node);
    visitor.leave(node);
  }
}
