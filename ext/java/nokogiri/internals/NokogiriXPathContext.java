package nokogiri.internals;

import org.apache.xml.dtm.DTMManager;
import org.apache.xpath.XPathContext;
import org.apache.xpath.objects.XMLStringFactoryImpl;

/**
 * An XPathContext that uses XalanDTMManagerPatch without looking it up by class name.
 *
 * Xalan's DTMManager.newInstance() looks up the manager class in the thread's context class loader
 * and in the class loader that loaded Xalan. In a servlet container with Xalan in WEB-INF/lib,
 * both are the webapp class loader, which cannot see nokogiri's classes.
 */
public final class NokogiriXPathContext extends XPathContext
{
  public
  NokogiriXPathContext()
  {
    super(false);
    m_dtmManager = newDTMManager();
  }

  public
  NokogiriXPathContext(Object owner)
  {
    super(owner, false);
    m_dtmManager = newDTMManager();
  }

  private static DTMManager
  newDTMManager()
  {
    DTMManager manager = new XalanDTMManagerPatch();
    manager.setXMLStringFactory(XMLStringFactoryImpl.getFactory());
    return manager;
  }
}
