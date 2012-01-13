require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class Term

    autoload :Type, 'lazy_tnetstring/term/type'

    attr_reader :data, :offset, :parent, :scope

    def initialize(data, offset, parent=nil, scope=nil)
      @data   = data
      @offset = offset
      @parent = parent
      @scope  = scope
      value_offset # raises InvalidTNetString if offset can not determined
    end

    def type
      @type ||= data[value_offset + value_length, 1]
    end

    def length
      @length = value_offset - offset + value_length + 1
    end

    def value_offset
      @value_offset ||= calculated_value_offset
    end

    def value_length
      @value_length ||= data[offset..(value_offset-2)].to_i
    end

    def value
      @value ||= typecast_raw_value
    end

    def raw_value
      @raw_value ||= data[value_offset, value_length]
    end

    def value=(new_value)
      self.raw_data = TNetstring.dump(new_value)
    end

    def value_length=(new_length)
      new_length_str = new_length.to_s
      data[offset..(value_offset-2)] = new_length_str
      @length = nil
      @value_offset = nil
    end

    def to_s
      "#<LazyTNetstring::Term:#{object_id} @offset=#{offset.inspect}(#{data[offset, 15]}...) @length=#{length.inspect} @value_length=#{value_length.inspect} @value=#{value.inspect}>"
    end

    private

    def calculated_value_offset
      colon_index = data[offset, 10].index(':')
      raise InvalidTNetString, "no length found in #{data[offset, 10]}..." unless colon_index
      calculated_offset = offset + colon_index + 1
      if !parent.nil?
        parent_end = parent.term.offset + parent.term.length - 1
        raise InvalidTNetString, "not inside scope (#{scope})" if calculated_offset > parent_end
      end
      calculated_offset
    end

    def raw_data=(new_raw_data)
      @data[offset, length] = new_raw_data
      @raw_value = nil
      @type = nil
      @length = nil
      @value_offset = nil
      @value_length = nil
    end

    def typecast_raw_value
      case type
      when Type::STRING     then raw_value
      when Type::INTEGER    then raw_value.to_i
      when Type::BOOLEAN    then boolean_from_raw_value
      when Type::NULL       then nil
      when Type::LIST       then array_from_raw_value
      when Type::DICTIONARY then LazyTNetstring::DataAccess.new(data, offset, parent, scope)
      else
        raise InvalidTNetString, "unknown term type #{type}"
      end
    end

    def boolean_from_raw_value
      case raw_value
      when 'true'  then true
      when 'false' then false
      else raise InvalidTNetString, "invalid boolean value #{raw_value}"
      end
    end

    def array_from_raw_value
      result = []
      position = 0
      while position < value_length do
        term = Term.new(data, value_offset + position)
        position += term.length
        result << term.value
      end

      result
    end

  end
end
