module Nokogiri
  module IoCallbacks # :nodoc:
    
    class << self
      if defined?(FFI::IO.native_read)
        def reader(io)
          lambda do |ctx, buffer, len|
            rcode = FFI::IO.native_read(io, buffer, len)
            (rcode < 0) ? 0 : rcode
          end
        end
      else
        def reader(io) # TODO: this can be removed once JRuby 1.3.0RC2 and ruby-ffi 0.4.0 are both released
          lambda do |ctx, buffer, len|
            string = io.read(len)
            return 0 if string.nil?
            buffer.put_bytes(0, string, 0, string.length)
            string.length
          end
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
