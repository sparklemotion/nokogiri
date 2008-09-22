module Nokogiri
  module XML
    module SAX
      class Document
        ###
        # Called when document starts parsing
        def start_document
        end

        ###
        # Called when document ends parsing
        def end_document
        end

        ###
        # Called at the beginning of an element
        # +name+ is the name of the tag with +attrs+ as attributes
        def start_element name, attrs = []
        end

        ###
        # Called at the end of an element
        # +name+ is the tag name
        def end_element name
        end

        ###
        # Characters read between a tag
        # +string+ contains the character data
        def characters string
        end

        ###
        # Called when comments are encountered
        # +string+ contains the comment data
        def comment string
        end

        ###
        # Called on document warnings
        # +string+ contains the warning
        def warning string
        end

        ###
        # Called on document errors
        # +string+ contains the error
        def error string
        end

        ###
        # Called when cdata blocks are found
        # +string+ contains the cdata content
        def cdata_block string
        end
      end
    end
  end
end
