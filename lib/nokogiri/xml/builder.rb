module Nokogiri
  module XML
    ###
    # Nokogiri builder can be used for building XML and HTML documents.
    #
    # == Synopsis:
    #
    #   builder = Nokogiri::XML::Builder.new do |xml|
    #     xml.root {
    #       xml.products {
    #         xml.widget {
    #           xml.id_ "10"
    #           xml.name "Awesome widget"
    #         }
    #       }
    #     }
    #   end
    #   puts builder.to_xml
    #
    # Will output:
    #
    #   <?xml version="1.0"?>
    #   <root>
    #     <products>
    #       <widget>
    #         <id>10</id>
    #         <name>Awesome widget</name>
    #       </widget>
    #     </products>
    #   </root>
    #
    #
    # === Builder scope
    #
    # The builder allows two forms.  When the builder is supplied with a block
    # that has a parameter, the outside scope is maintained.  This means you
    # can access variables that are outside your builder.  If you don't need
    # outside scope, you can use the builder without the "xml" prefix like
    # this:
    #
    #   builder = Nokogiri::XML::Builder.new do
    #     root {
    #       products {
    #         widget {
    #           id_ "10"
    #           name "Awesome widget"
    #         }
    #       }
    #     }
    #   end
    #
    # == Special Tags
    #
    # The builder works by taking advantage of method_missing.  Unfortunately
    # some methods are defined in ruby that are difficult or dangerous to
    # remove.  You may want to create tags with the name "type", "class", and
    # "id" for example.  In that case, you can use an underscore to
    # disambiguate your tag name from the method call.
    #
    # Here is an example of using the underscore to disambiguate tag names from
    # ruby methods:
    #
    #   @objects = [Object.new, Object.new, Object.new]
    #
    #   builder = Nokogiri::XML::Builder.new do |xml|
    #     xml.root {
    #       xml.objects {
    #         @objects.each do |o|
    #           xml.object {
    #             xml.type_   o.type
    #             xml.class_  o.class.name
    #             xml.id_     o.id
    #           }
    #         end
    #       }
    #     }
    #   end
    #   puts builder.to_xml
    #
    # The underscore may be used with any tag name, and the last underscore
    # will just be removed.  This code will output the following XML:
    #
    #   <?xml version="1.0"?>
    #   <root>
    #     <objects>
    #       <object>
    #         <type>Object</type>
    #         <class>Object</class>
    #         <id>48390</id>
    #       </object>
    #       <object>
    #         <type>Object</type>
    #         <class>Object</class>
    #         <id>48380</id>
    #       </object>
    #       <object>
    #         <type>Object</type>
    #         <class>Object</class>
    #         <id>48370</id>
    #       </object>
    #     </objects>
    #   </root>
    #
    # == Tag Attributes
    #
    # Tag attributes may be supplied as method arguments.  Here is our
    # previous example, but using attributes rather than tags:
    #
    #   @objects = [Object.new, Object.new, Object.new]
    #
    #   builder = Nokogiri::XML::Builder.new do |xml|
    #     xml.root {
    #       xml.objects {
    #         @objects.each do |o|
    #           xml.object(:type => o.type, :class => o.class, :id => o.id)
    #         end
    #       }
    #     }
    #   end
    #   puts builder.to_xml
    #
    # === Tag Attribute Short Cuts
    #
    # A couple attribute short cuts are available when building tags.  The
    # short cuts are available by special method calls when building a tag.
    #
    # This example builds an "object" tag with the class attribute "classy"
    # and the id of "thing":
    #
    #   builder = Nokogiri::XML::Builder.new do |xml|
    #     xml.root {
    #       xml.objects {
    #         xml.object.classy.thing!
    #       }
    #     }
    #   end
    #   puts builder.to_xml
    #
    # Which will output:
    #
    #   <?xml version="1.0"?>
    #   <root>
    #     <objects>
    #       <object class="classy" id="thing"/>
    #     </objects>
    #   </root>
    #
    # All other options are still supported with this syntax, including
    # blocks and extra tag attributes.
    class Builder
      # The current Document object being built
      attr_accessor :doc

      # The parent of the current node being built
      attr_accessor :parent

      # A context object for use when the block has no arguments
      attr_accessor :context

      attr_accessor :arity # :nodoc:

      ###
      # Create a new Builder object.  +options+ are sent to the top level
      # Document that is being built.
      #
      # Building a document with a particular encoding for example:
      #
      #   Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      #     ...
      #   end
      def initialize options = {}, &block
        namespace = self.class.name.split('::')
        namespace[-1] = 'Document'
        @doc      = eval(namespace.join('::')).new
        @parent   = @doc
        @context  = nil
        @arity    = nil

        options.each do |k,v|
          @doc.send(:"#{k}=", v)
        end

        return unless block_given?

        @arity = block.arity
        if @arity <= 0
          @context = eval('self', block.binding)
          instance_eval(&block)
        else
          yield self
        end

        @parent = @doc
      end

      ###
      # Create a Text Node with content of +string+
      def text string
        node = Nokogiri::XML::Text.new(string.to_s, @doc)
        insert(node)
      end

      ###
      # Create a CDATA Node with content of +string+
      def cdata string
        node = Nokogiri::XML::CDATA.new(@doc, string.to_s)
        insert(node)
      end

      ###
      # Convert this Builder object to XML
      def to_xml
        @doc.to_xml
      end

      def method_missing method, *args, &block # :nodoc:
        if @context && @context.respond_to?(method)
          @context.send(method, *args, &block)
        else
          node = Nokogiri::XML::Node.new(method.to_s.sub(/[_!]$/, ''), @doc) { |n|
            args.each do |arg|
              case arg
              when Hash
                arg.each { |k,v| n[k.to_s] = v.to_s }
              else
                n.content = arg
              end
            end
          }
          insert(node, &block)
        end
      end

      private
      ###
      # Insert +node+ as a child of the current Node
      def insert(node, &block)
        node.parent = @parent
        if block_given?
          @parent = node
          @arity ||= block.arity
          if @arity <= 0
            instance_eval(&block)
          else
            block.call(self)
          end
          @parent = node.parent
        end
        NodeBuilder.new(node, self)
      end

      class NodeBuilder # :nodoc:
        def initialize(node, doc_builder)
          @node = node
          @doc_builder = doc_builder
        end

        def []= k, v
          @node[k] = v
        end

        def [] k
          @node[k]
        end

        def method_missing(method, *args, &block)
          opts = args.last.is_a?(Hash) ? args.pop : {}
          case method.to_s
          when /^(.*)!$/
            @node['id'] = $1
            @node.content = args.first if args.first
          when /^(.*)=/
            @node[$1] = args.first
          else
            @node['class'] = 
              ((@node['class'] || '').split(/\s/) + [method.to_s]).join(' ')
            @node.content = args.first if args.first
          end

          # Assign any extra options
          opts.each do |k,v|
            @node[k.to_s] = ((@node[k.to_s] || '').split(/\s/) + [v]).join(' ')
          end

          if block_given?
            old_parent = @doc_builder.parent
            @doc_builder.parent = @node
            value = @doc_builder.instance_eval(&block)
            @doc_builder.parent = old_parent
            return value
          end
          self
        end
      end
    end
  end
end
