require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class Term

    autoload :Type, 'lazy_tnetstring/term/type'
    include LazyTNetstring::Netstring

    attr_reader :data, :offset, :length, :value_length, :value_offset, :parent, :scope

    def initialize(data, offset, parent=nil, scope=nil)
      @data   = data
      @offset = offset
      @parent = parent
      @scope  = scope
      update_indices_and_length
    end

    def value
      case type_id
      when Type::STRING     then raw_value
      when Type::INTEGER    then raw_value.to_i
      when Type::BOOLEAN    then boolean_from_raw_value
      when Type::NULL       then nil
      when Type::LIST       then array_from_raw_value
      when Type::DICTIONARY then LazyTNetstring::DataAccess.new(data, offset, value_offset-offset+value_length+1, parent, scope)
      else
        raise InvalidTNetString, "unknown term type #{type_id}"
      end
    end

    def raw_value
      @raw_value ||= data[value_offset, value_length]
    end

    def value=(new_value)
      self.raw_data = TNetstring.dump(new_value)
    end

    def raw_data=(new_raw_data)
      @data[offset, value_offset-offset+value_length+1] = new_raw_data
      @raw_value = nil
      update_indices_and_length
    end

    def to_s
      "#<LazyTNetstring::Term:#{object_id} @offset=#{offset.inspect}(#{data[offset, 15]}...) @length=#{length.inspect} @value_length=#{value_length.inspect} @value=#{value.inspect}>"
    end

    private

    def type_id
      data[value_offset + value_length, 1]
    end

    def boolean_from_raw_value
      case raw_value
      when 'true' then true
      when 'false' then false
      else raise InvalidTNetString, "invalid boolean value #{raw_value}"
      end
    end

    def array_from_raw_value
      result = []
      position = 0
      while position < value_length do
        term = Term.new(data, value_offset + position)
        result << term.value
        position += term.length
      end

      result
    end

    def update_indices_and_length
      @value_offset = value_offset_for(data, offset)
      @value_length = data[offset..(value_offset-2)].to_i
      @length       = value_offset - offset + value_length + 1
    end

  end
end
