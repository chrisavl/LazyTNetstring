require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class Term

    autoload :Type, 'lazy_tnetstring/term/type'

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
      "#<LazyTNetstring::Term:#{object_id} @offset=#{offset.inspect} @value_length=#{value_length.inspect} @value=#{value.inspect}>"
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
      offset = 0
      while colon_index = raw_value[offset..-1].index(':') do
        element_offset = offset + colon_index + 1
        element_length = raw_value[offset..(element_offset - 1)].to_i
        result << Term.new(data, @value_offset + offset).value
        offset = element_offset + element_length + 1
      end

      result
    end

    def update_indices_and_length
      @value_offset = recalculated_value_offset
      @value_length = data[offset..(value_offset-2)].to_i
      @length       = value_length + value_offset + 1
    end

    def recalculated_value_offset
      colon_index = data[offset, 10].index(':')
      raise InvalidTNetString, "no length found in #{data[offset, 10]}..." unless colon_index
      offset + colon_index + 1
    end

  end
end
