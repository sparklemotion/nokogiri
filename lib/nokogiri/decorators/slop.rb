module Nokogiri
  module Decorators
    module Slop
      def method_missing name, *args, &block
        if args.empty?
          list = xpath("./#{name}")
        elsif args.first.is_a? Hash
          hash = args.first
          if hash[:css]
            list = css("#{name}#{hash[:css]}")
          elsif hash[:xpath]
            conds = Array(hash[:xpath]).collect{|j| "[#{j}]"}
            list = xpath("./#{name}#{conds}")
          end
        else
          list = css("#{name}#{args.first}")
        end
        
        super if list.empty?
        list.length == 1 ? list.first : list
      end
    end
  end
end
