ROOT_DIR = File.dirname(__FILE__)
#require File.join(ROOT_DIR, 'helper')
XML_DIR = File.join(ROOT_DIR,'xml')
load File.join(ROOT_DIR, 'test_reader.rb')
load File.join(XML_DIR, 'test_namespace.rb')
load File.join(XML_DIR, 'test_node.rb')
load File.join(XML_DIR, 'test_node_attributes.rb')
load File.join(XML_DIR, 'test_attr.rb')
load File.join(XML_DIR, 'test_cdata.rb')
load File.join(XML_DIR, 'test_comment.rb')
load File.join(XML_DIR, 'test_document.rb')

#suite = TestSuite.new "JRuby test"
#suite << TestReader
#suite << Nokogiri::XML::TestNamespace
#suite << Nokogiri::XML::TestNodeAttributes
