package nokogiri.internals;

/**
 * Interface for receiving xmlDecl information.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
public interface XmlDeclHandler
{
  public void xmlDecl(String version, String encoding, String standalone);
}
