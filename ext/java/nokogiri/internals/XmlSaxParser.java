package nokogiri.internals;

import org.apache.xerces.parsers.SAXParser;
import org.apache.xerces.xni.Augmentations;
import org.apache.xerces.xni.XNIException;

/**
 * Extends SAXParser in order to receive xmlDecl events and pass them
 * on to a handler.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
public class XmlSaxParser extends SAXParser
{

  protected XmlDeclHandler xmlDeclHandler = null;

  public
  XmlSaxParser()
  {
    super();
  }

  public void
  setXmlDeclHandler(XmlDeclHandler xmlDeclHandler)
  {
    this.xmlDeclHandler = xmlDeclHandler;
  }

  @Override
  public void
  xmlDecl(String version, String encoding, String standalone,
          Augmentations augs) throws XNIException
  {
    super.xmlDecl(version, encoding, standalone, augs);
    if (xmlDeclHandler != null) {
      xmlDeclHandler.xmlDecl(version, encoding, standalone);
    }
  }
}
