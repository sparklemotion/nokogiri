# :stopdoc:
if ENV['NOKOGIRI_ID2REF'] || RUBY_PLATFORM !~ /java/
  Nokogiri::VERSION_INFO['refs'] = "id2ref"
else
  require 'weakling'
  Nokogiri::VERSION_INFO['refs'] = "weakling"
end

module Nokogiri
  class WeakBucket
    if Nokogiri::VERSION_INFO['refs'] == "weakling"
      @@bucket = Weakling::IdHash.new
      @@semaphore = Mutex.new

      def WeakBucket.get_object(cstruct)
        @@semaphore.synchronize do
          @@bucket[cstruct.ruby_node_pointer]
        end
      end

      def WeakBucket.set_object(cstruct, object)
        @@semaphore.synchronize do
          cstruct.ruby_node_pointer = @@bucket.add(object)
        end
      end

    else

      def WeakBucket.get_object(cstruct)
        ptr = cstruct.ruby_node_pointer
        ptr != 0 ? ObjectSpace._id2ref(ptr) : nil
      end

      def WeakBucket.set_object(cstruct, object)
        cstruct.ruby_node_pointer = object.object_id
      end
    end
  end
end
# :startdoc:
