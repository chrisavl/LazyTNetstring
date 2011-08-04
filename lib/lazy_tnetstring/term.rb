module LazyTNetstring

  class Term
    attr_accessor :offset, :length
    attr_reader :data

    def initialize(data, offset, length)
      @data = data
      @offset = offset
      @length = length
    end

    def value
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
  end

end
