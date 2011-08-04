module LazyTNetstring

  class Term

    module Type
      STRING     = ','
      INTEGER    = '#'
      BOOLEAN    = '!'
      NULL       = '~'
      DICTIONARY = '}'
      LIST       = ']'
    end

    attr_accessor :offset, :length
    attr_reader :data

    def initialize(data, offset, length)
      @data = data
      @offset = offset
      @length = length
    end

    def value
      case type_id
      when Type::STRING then @data[@offset, @length]
      when Type::INTEGER then @data[@offset, @length].to_i
      when Type::DICTIONARY then @data[@offset, @length] # TODO: couldn't the Term be responsible for providing a new Parser for Dictionaries?
      else
        raise "unknown term type #{type_id}"
      end
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
  end

end
