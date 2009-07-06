/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 *
 * @author sergio
 */
public class XmlElement extends XmlNode {

    public XmlElement(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    public XmlElement(Ruby runtime, RubyClass klazz, Node element) {
        super(runtime, klazz, element);
    }
}
