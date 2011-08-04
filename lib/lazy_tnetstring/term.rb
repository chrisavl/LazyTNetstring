require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class Term

    autoload :Type, 'lazy_tnetstring/term/type'

    attr_accessor :offset, :length
    attr_reader :data, :value_offset

    def initialize(data, offset)
      @data = data
      @offset = offset
      colon_index = data[offset..-1].index(':')
      raise ::LazyTNetstring::KeyNotFoundError, 'Key not found' unless colon_index

      @value_offset = offset + colon_index + 1
      @length = data[offset..(@value_offset - 1)].to_i
    end

    def value
      case type_id
      when Type::STRING     then raw_value
      when Type::INTEGER    then raw_value.to_i
      when Type::BOOLEAN    then boolean_from_raw_value
      when Type::NULL       then nil
      when Type::LIST       then array_from_raw_value
      when Type::DICTIONARY then LazyTNetstring::Parser.new(data, offset, value_offset-offset+length)
      else
        raise "unknown term type #{type_id}"
      end
    end

    def raw_value
      @raw_value ||= data[value_offset, length]
    end

    def to_s
      "LazyTNetstring::Term(offset=#{offset}, length=#{length}) => #{self.value.inspect}"
    end

    private

    def type_id
      data[value_offset + length, 1]
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
      while colon_index = raw_value[offset..-1].index(':') do
        value_offset = offset + colon_index + 1
        value_length = raw_value[offset..(value_offset - 1)].to_i
        result << Term.new(data, @value_offset + offset)
        offset = value_offset + value_length + 1
      end

      result.map(&:value)
    end

  end
end
