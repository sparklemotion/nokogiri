package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.w3c.dom.Node;
import org.w3c.dom.UserDataHandler;

/**
 *
 * @author sergio
 */
public class NokogiriUserDataHandler implements UserDataHandler {

    public static final String CACHED_NODE = "NOKOGIRI_CACHED_NODE";

    protected Ruby ruby;

    public NokogiriUserDataHandler(Ruby ruby) {
        this.ruby = ruby;
    }

    public void handle(short opCode, String key, Object data, Node src, Node dst) {
        switch(opCode) {
            case UserDataHandler.NODE_ADOPTED:
                this.nodeAdopted(key, data, src, dst);
                break;
            case UserDataHandler.NODE_CLONED:
                this.nodeCloned(key, data, src, dst);
                break;
            case UserDataHandler.NODE_DELETED:
                this.nodeDeleted(key, data, src, dst);
                break;
            case UserDataHandler.NODE_IMPORTED:
                this.nodeImported(key, data, src, dst);
                break;
            case UserDataHandler.NODE_RENAMED:
                this.nodeRenamed(key, data, src, dst);
                break;
        }
    }

    private void nodeAdopted(String key, Object data, Node src, Node dst) {
        if(CACHED_NODE.equals(key)) {
            ((XmlNode) data).resetCache(ruby);
        }
    }

    private void nodeCloned(String key, Object data, Node src, Node dst) {
        if(CACHED_NODE.equals(key)) {
            NokogiriHelpers.getCachedNodeOrCreate(ruby, dst);
        }
    }

    private void nodeDeleted(String key, Object data, Node src, Node dst) {
        // Nothing to do.
//        if(CACHED_NODE.equals(key)) {
//
//        }
    }

    private void nodeImported(String key, Object data, Node src, Node dst) {
        if(CACHED_NODE.equals(key)) {
            // Importing creates a new node, so same as in clone.
            NokogiriHelpers.getCachedNodeOrCreate(ruby, dst);
        }
    }

    private void nodeRenamed(String key, Object data, Node src, Node dst) {
        if(CACHED_NODE.equals(key)) {
            ((XmlNode) data).resetCache(ruby);
        }
    }

}
