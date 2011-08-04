module LazyTNetstring

  class Term
    attr_accessor :offset, :length

    def initialize(data, offset, length)
      @data = data
      @offset = offset
      @length = length
    end

    def value
      @data[@offset, @length]
    end

    def is_leaf?
      @data[@offset + @length, 1] != '}'
    end

    def to_s
      "(offset=#{@offset}, length=#{@length}) => #{self.value.inspect} [#{self.is_leaf? ? 'leaf' : 'node'}]"
    end
  end

end
