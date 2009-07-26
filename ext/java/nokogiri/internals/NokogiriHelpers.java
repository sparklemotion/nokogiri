/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri.internals;

import org.w3c.dom.Attr;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

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

    public static String getNodeCompletePath(Node node) {

        Node cur, tmp, next;

        // TODO: Rename buffer to path.
        String buffer = "";
        String sep;
        String name;

        int occur = 0, generic;

        cur = node;

        do {
            name = "";
            sep = "?";
            occur = 0;
            generic = 0;

            if(cur.getNodeType() == Node.DOCUMENT_NODE) {
                if(buffer.startsWith("/")) break;

                sep = "/";
                next = null;
            } else if(cur.getNodeType() == Node.ELEMENT_NODE) {
                generic = 0;
                sep = "/";

                name = cur.getLocalName();
                if(cur.getNamespaceURI() != null) {
                    if(cur.getPrefix() != null) {
                        name = cur.getPrefix() + ":" + name;
                    } else {
                        generic = 1;
                        name = "*";
                    }
                }

                next = cur.getParentNode();

                /*
                 * Thumbler index computation
                 */

                tmp = cur.getPreviousSibling();

                while(tmp != null) {
                    if((tmp.getNodeType() == Node.ELEMENT_NODE) &&
                        (generic != 0 || compareTwoNodes(tmp,cur))) {
                        occur++;
                    }
                    tmp = tmp.getPreviousSibling();
                }

                if(occur == 0) {
                    tmp = cur.getNextSibling();

                    while(tmp != null && occur == 0) {
                        if((tmp.getNodeType() == Node.ELEMENT_NODE) &&
                            (generic != 0 || compareTwoNodes(tmp,cur))) {
                            occur++;
                        }
                        tmp = tmp.getNextSibling();
                    }

                    if(occur != 0) occur = 1;

                } else {
                    occur++;
                }
            } else if(cur.getNodeType() == Node.COMMENT_NODE) {
                sep = "/";
                name = "comment()";
                next = cur.getParentNode();

                /*
                 * Thumbler index computation.
                 */

                tmp = cur.getPreviousSibling();

                while(tmp != null) {
                    if(tmp.getNodeType() == Node.COMMENT_NODE) {
                        occur++;
                    }
                    tmp = tmp.getPreviousSibling();
                }

                if(occur == 0) {
                    tmp = cur.getNextSibling();
                    while(tmp != null && occur == 0) {
                        if(tmp.getNodeType() == Node.COMMENT_NODE) {
                            occur++;
                        }
                        tmp = tmp.getNextSibling();
                    }
                    if(occur != 0) occur = 1;
                } else {
                    occur = 1;
                }

            } else if(cur.getNodeType() == Node.TEXT_NODE ||
                cur.getNodeType() == Node.CDATA_SECTION_NODE) {
                    // I'm here. gist:129
                    // http://gist.github.com/144923

                sep = "/";
                name = "text()";
                next = cur.getParentNode();

                /*
                 * Thumbler index computation.
                 */

                tmp = cur.getPreviousSibling();
                while(tmp != null) {
                    if(tmp.getNodeType() == Node.TEXT_NODE ||
                            tmp.getNodeType() == Node.CDATA_SECTION_NODE) {
                        occur++;
                    }
                    tmp = tmp.getPreviousSibling();
                }

                if(occur == 0) {
                    tmp = cur.getNextSibling();

                    while(tmp != null && occur == 0) {
                        if(tmp.getNodeType() == Node.TEXT_NODE ||
                                tmp.getNodeType() == Node.CDATA_SECTION_NODE) {
                            occur++;
                        }
                        tmp = tmp.getNextSibling();
                    }
                } else {
                    occur++;
                }

            } else if(cur.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE) {
                sep = "/";
                name = "processing-instruction('"+cur.getLocalName()+"')";
                next = cur.getParentNode();

                /*
                 * Thumbler index computation.
                 */

                tmp = cur.getParentNode();

                while(tmp != null) {
                    if(tmp.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE &&
                            tmp.getLocalName().equals(cur.getLocalName())) {
                        occur++;
                    }
                    tmp = tmp.getPreviousSibling();
                }

                if(occur == 0) {
                    tmp = cur.getNextSibling();

                    while(tmp != null && occur == 0) {
                        if(tmp.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE &&
                                tmp.getLocalName().equals(cur.getLocalName())){
                            occur++;
                        }
                        tmp = tmp.getNextSibling();
                    }

                    if(occur != 0) {
                        occur = 1;
                    }

                } else {
                    occur++;
                }

            } else if(cur.getNodeType() == Node.ATTRIBUTE_NODE) {
                sep = "/@";
                name = cur.getLocalName();

                if(cur.getNamespaceURI() != null) {
                    if(cur.getPrefix() != null) {
                        name = cur.getPrefix() + ":" + name;
                    }
                }

                next = ((Attr) cur).getOwnerElement();

            } else {
                next = cur.getParentNode();
            }

            if(occur == 0){
                buffer = sep+name+buffer;
            } else {
                buffer = sep+name+"["+occur+"]"+buffer;
            }

            cur = next;

        } while(cur != null);

        return buffer;
    }

    protected static boolean compareTwoNodes(Node m, Node n) {
        return (m.getLocalName().equals(n.getLocalName()) &&
                (((m.getPrefix() == null) && (n.getPrefix() == null)) ||
                (m.getPrefix() != null) && (n.getPrefix() != null) &&
                (n.getPrefix().equals(m.getPrefix()))));
    }

    public static String getNodeName(Node node) {
        if(node == null) return "";
        String name = node.getNodeName();
        if(name == null) return "";
        if(name.equals("#document")) {
            return "document";
        } else if(name.equals("#text")) {
            return "text";
        } else {
            name = node.getLocalName();
            return (name == null) ? "" : name;
        }
    }

    public static boolean isNamespace(Node node) {
        return isNamespace(node.getNodeName());
    }

    public static boolean isNamespace(String string) {
        return string.equals("xmlns") || string.startsWith("xmlns:");
    }

    public static String newQName(String newPrefix, Node node) {
        if(newPrefix == null) {
            return node.getLocalName();
        } else {
            return newPrefix + ":" + node.getLocalName();
        }
    }
}
