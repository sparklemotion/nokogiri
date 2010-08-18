package nokogiri.internals;
import java.util.HashMap;
import javax.xml.namespace.QName;
import javax.xml.xpath.XPathVariableResolver;

public class NokogiriXPathVariableResolver
    implements XPathVariableResolver{

    private HashMap<QName,String> variables=new HashMap<QName,String>();

    public Object resolveVariable(QName variableName){
        return variables.get(variableName);
    }
    public void registerVariable(String name,String value){
        variables.put(QName.valueOf(name),value);
    }
}
