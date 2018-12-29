# this is a generated file, to avoid over-writing it just delete this comment
begin
  require 'jar_dependencies'
rescue LoadError
  require 'xerces/xercesImpl/2.12.0/xercesImpl-2.12.0.jar'
  require 'xml-apis/xml-apis/1.4.01/xml-apis-1.4.01.jar'
end

if defined? Jars
  require_jar 'xerces', 'xercesImpl', '2.12.0'
  require_jar 'xml-apis', 'xml-apis', '1.4.01'
end
