require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class Term

    autoload :Type, 'lazy_tnetstring/term/type'

    attr_accessor :offset, :length
    attr_reader :data

    def initialize(data, offset, length)
      @data = data
      @offset = offset
      @length = length
    end

    def value
      case type_id
      when Type::STRING then raw_value
      when Type::INTEGER then raw_value.to_i
      when Type::BOOLEAN then boolean_from_raw_value
      when Type::NULL then nil
      when Type::LIST then array_from_raw_value
      when Type::DICTIONARY then @data[@offset, @length] # TODO: couldn't the Term be responsible for providing a new Parser for Dictionaries?
      else
        raise "unknown term type #{type_id}"
      end
    end

    def raw_value
      @data[@offset, @length]
    end

    def is_leaf?
      type_id != '}'
    end

    def to_s
      "(offset=#{@offset}, length=#{@length}) => #{self.value.inspect} [#{self.is_leaf? ? 'leaf' : 'node'}]"
    end

    private

    def type_id
      @data[@offset + @length, 1]
    end

    def boolean_from_raw_value
      case raw_value
      when 'true' then true
      when 'false' then false
      else raise 'invalid boolean value #{value}'
      end
    end

    def array_from_raw_value
      result = []
      offset = 0
      data = raw_value
      while colon_index = data[offset..-1].index(':') do
        value_offset = offset + colon_index + 1
        value_length = data[offset..(value_offset - 1)].to_i
        result << Term.new(@data, @offset + value_offset, value_length)
        offset = value_offset + value_length + 1
      end

      result.map(&:value)
    end
  end

end
