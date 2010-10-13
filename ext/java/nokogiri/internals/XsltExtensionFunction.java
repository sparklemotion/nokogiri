package nokogiri.internals;

import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import nokogiri.XsltStylesheet;

/**
 * XSLT extension function caller. Currently, this class is not used because
 * parsing XSL file with extension function (written in Java) fails. The reason of 
 * the failure is a conflict of Java APIs. When xercesImpl.jar or jing.jar, or both
 * are on a classpath, parsing fails. Assuming parsing passes, this class will be
 * used as in below:
 * 
 * <xsl:stylesheet
 *      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 *      xmlns:f="xalan://nokogiri.internals.XsltExtensionFunction"
 *      extension-element-prefixes="f"
 *      version="1.0">
 *   <xsl:template match="text()">
 *     <xsl:copy-of select="f:call('capitalize', string(.))"/>
 *   </xsl:template>
 *   ...
 *  </xsl:stylesheet>
 *
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XsltExtensionFunction {
    public static Object call(String method, Object arg) {
        if (XsltStylesheet.getRegistry() == null) return null;
        ThreadContext context = (ThreadContext) XsltStylesheet.getRegistry().get("context");
        IRubyObject receiver = (IRubyObject)XsltStylesheet.getRegistry().get("receiver");
        if (context == null || receiver == null) return null;
        IRubyObject arg0 = JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), arg);
        IRubyObject result = RuntimeHelpers.invoke(context, receiver, method, arg0);
        return result.toJava(Object.class);
    }
}
