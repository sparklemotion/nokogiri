package nokogiri.internals;

import java.util.HashMap;
import javax.xml.namespace.QName;
import javax.xml.xpath.XPathVariableResolver;

/**
 * XPath variable support
 *
 * @author Ken Bloom <kbloom@gmail.com>
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriXPathVariableResolver implements XPathVariableResolver
{

  private final HashMap<QName, String> variables = new HashMap<QName, String>();

  public static NokogiriXPathVariableResolver
  create()
  {
    return new NokogiriXPathVariableResolver();
  }

  private
  NokogiriXPathVariableResolver() {}

  public Object
  resolveVariable(QName variableName)
  {
    return variables.get(variableName);
  }
  public void
  registerVariable(String name, String value)
  {
    variables.put(new QName(name), value);
  }
}
