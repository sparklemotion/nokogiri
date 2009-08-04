package nokogiri.internals;

import java.io.IOException;
import java.io.InputStream;
import javax.xml.parsers.ParserConfigurationException;
import org.cyberneko.html.parsers.DOMParser;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.xml.sax.SAXException;

/**
 *
 * @author sergio
 */
public class HtmlParseOptions extends ParseOptions{

    public HtmlParseOptions(IRubyObject options) {
        super(options);
    }

    public HtmlParseOptions(long options) {
        super(options);
    }

    @Override
    public Document parse(InputStream input)
            throws ParserConfigurationException, SAXException, IOException {
        DOMParser parser = new DOMParser();

        parser.parse(input.toString());
        return parser.getDocument();
    }
}
