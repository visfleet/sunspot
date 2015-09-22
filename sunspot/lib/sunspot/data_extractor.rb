module Sunspot
  #
  # lifted from https://github.com/sunspot/sunspot/issues/570
  # :: combined rwc9u && rajiteh's answers ::
  #
  #
  # DataExtractors present an internal API for the indexer to use to extract
  # field values from models for indexing. They must implement the #value_for
  # method, which takes an object and returns the value extracted from it.
  #
  module DataExtractor #:nodoc: all
    #
    # AttributeExtractors extract data by simply calling a method on the block.
    #
    class AttributeExtractor
      def initialize(attribute_name)
        @attribute_name = attribute_name
      end

      def value_for(object)
        Filter.new( object.send(@attribute_name) ).value
      end
    end

    #
    # BlockExtractors extract data by evaluating a block in the context of the
    # object instance, or if the block takes an argument, by passing the object
    # as the argument to the block. Either way, the return value of the block is
    # the value returned by the extractor.
    #
    class BlockExtractor
      def initialize(&block)
        @block = block
      end

      def value_for(object)
        Filter.new( Util.instance_eval_or_call(object, &@block) ).value
      end
    end

    #
    # Constant data extractors simply return the same value for every object.
    #
    class Constant
      def initialize(value)
        @value = value
      end

      def value_for(object)
        Filter.new(@value).value
      end
    end

    #
    # A Filter to allow easy value cleaning
    #
    class Filter
      def initialize(value)
        @value = value
      end
      def value
        if @value.is_a? String
          strip_control_characters @value
        elsif @value.is_a? Array
          @value.map { |v| strip_control_characters v }
        elsif @value.is_a? Hash
          @value.inject({}) do |hash, (k, v)|
            hash.merge( strip_control_characters(k) => strip_control_characters(v) )
          end
        else
          @value
        end
      end
      def strip_control_characters(value)
        return value unless value.is_a? String
        value.encode(value.encoding, "binary", invalid: :replace, undef: :replace).gsub(/[[:cntrl:]]/,'')
      end
    end

  end
end