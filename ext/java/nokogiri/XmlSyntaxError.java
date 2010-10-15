/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2010:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com]
 * * {Sergio Arbeo}[http://www.serabe.com]
 * * {Patrick Mahoney}[http://polycrystal.org]
 * * {Yoko Harada}[http://yokolet.blogspot.com]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri;

import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyClass;
import org.xml.sax.SAXParseException;

/**
 * Class for Nokogiri::XML::SyntaxError
 *
 */
@JRubyClass(name="Nokogiri::XML::SyntaxError", parent="Nokogiri::SyntaxError")
public class XmlSyntaxError extends RubyException {

    protected Exception exception;

    public static RubyClass getRubyClass(Ruby ruby) {
        return ((RubyModule) ruby.getModule("Nokogiri").getConstant("XML")).getClass("SyntaxError");
    }

    public XmlSyntaxError(Ruby ruby){
        this(ruby, getRubyClass(ruby));
    }

    public XmlSyntaxError(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    public XmlSyntaxError(Ruby ruby, Exception ex) {
        this(ruby);
        this.exception = ex;
    }

    public XmlSyntaxError(Ruby ruby, RubyClass rubyClass, Exception ex) {
        super(ruby, rubyClass, ex.getMessage());
        this.exception = ex;
    }

    public static XmlSyntaxError createWarning(Ruby ruby, SAXParseException e) {
        return new XmlSyntaxError(ruby, e, 1);
    }

    public static XmlSyntaxError createError(Ruby ruby, SAXParseException e) {
        return new XmlSyntaxError(ruby, e, 2);
    }

    public static XmlSyntaxError createFatalError(Ruby ruby, SAXParseException e) {
        return new XmlSyntaxError(ruby, e, 3);
    }

    public XmlSyntaxError(Ruby ruby, SAXParseException e, int level) {
        super(ruby, getRubyClass(ruby), e.getMessage());
        this.exception = e;
        setInstanceVariable("@level", ruby.newFixnum(level));
        setInstanceVariable("@line", ruby.newFixnum(e.getLineNumber()));
        setInstanceVariable("@column", ruby.newFixnum(e.getColumnNumber()));
        setInstanceVariable("@file", stringOrNil(ruby, e.getSystemId()));
    }

    public static RubyException createXPathSyntaxError(Ruby runtime, Exception e) {
        RubyClass klazz = (RubyClass)
            runtime.getClassFromPath("Nokogiri::XML::XPath::SyntaxError");
        return new XmlSyntaxError(runtime, klazz, e);
    }

}
