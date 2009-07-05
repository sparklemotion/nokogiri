/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri;

import org.w3c.dom.Node;

/**
 *
 * @author serabe
 */
public class NokogiriHelpers {

    public static String getLocalName(String name) {
        int index = name.indexOf(':');
        if(index == -1) {
            return null;
        } else {
            return name.substring(index+1);
        }
    }

    public static String getNodeName(Node node) {
        String name = node.getNodeName();
        if(name.equals("#document")) {
            return "document";
        } else if(name.equals("#text")) {
            return "text";
        } else {
            return name;
        }
    }

    public static boolean isNamespace(Node node) {
        return isNamespace(node.getNodeName());
    }

    public static boolean isNamespace(String string) {
        return string.equals("xmlns") || string.startsWith("xmlns:");
    }
}
