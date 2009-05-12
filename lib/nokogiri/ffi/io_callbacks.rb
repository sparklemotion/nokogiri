module Nokogiri
  module IoCallbacks # :nodoc:
    
    class << self
      def reader(io)
        lambda do |ctx, buffer, len|
          string = io.read(len)
          return 0 if string.nil?
          buffer.put_bytes(0, string, 0, string.length)
          string.length
        end
      end

      def writer(io)
        lambda do |context, buffer, len|
          io.write buffer
          len
        end
      end
    end

  end
end
