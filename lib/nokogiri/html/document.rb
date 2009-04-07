module Nokogiri
  module HTML
    class Document < XML::Document
      ####
      # Serialize this Document with +encoding+ using +options+
      def serialize *args
        if args.first && !args.first.is_a?(Hash)
          $stderr.puts(<<-eowarn)
#{self.class}#serialize(encoding, save_opts) is deprecated and will be removed in
Nokogiri version 1.4.0 *or* after June 1 2009.
You called serialize from here:

  #{caller.join("\n")}

Please change to #{self.class}#serialize(:encoding => enc, :save_with => opts)
          eowarn
        end

        options = args.first.is_a?(Hash) ? args.shift : {
          :encoding   => args[0],
          :save_with  => args[1] || XML::Node::SaveOptions::FORMAT |
            XML::Node::SaveOptions::AS_HTML |
            XML::Node::SaveOptions::NO_DECLARATION |
            XML::Node::SaveOptions::NO_EMPTY_TAGS
        }
        super(options)
      end
    end
  end
end
