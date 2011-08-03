module LazyTNetstring

  class KeyNotFoundError < Exception
  end

  class Parser

    attr_reader :data, :offset, :length

    def initialize(data, offset=0, length=data.length)
      raise "Invalid data #{data.inspect}" unless data.end_with? '}'
      @data = data
      @offset = offset
      @length = length
    end

    def [](key)
      found_key = find_key(key)
      found_value = term_following found_key
      if found_value.is_leaf?
        found_value.value
      else
        node_offset = found_value.offset - found_value.length.to_s.length - 1
        node_length = found_value.length.to_s.length + 1 + found_value.length
        Parser.new(data, node_offset, node_length) # includes leading size and ':' as well as trailing '}'
      end
    end

    def find_key(key)
      offset = hash_data.index(':') + 1
      term = next_term(offset)
      term_type = :key

      loop do
        if key == term.value && term_type == :key
          return term
        end
        offset = term.offset + term.length + 1
        term = term_following term # may throw an KeyNotFoundException to abort looping
        term_type = (term_type == :key ? :value : :key)
      end
    end

    def hash_data
      @data[@offset..(@offset + @length)]
    end

    def term_following(term)
      next_term(term.offset + term.length + 1)
    end

    def next_term(offset)
      colon_index = hash_data[offset..-1].index(':')
      raise KeyNotFoundError, "Key not found" unless colon_index

      key_offset = offset + colon_index + 1
      key_length = hash_data[offset..(key_offset - 1)].to_i
      Term.new(hash_data, key_offset, key_length)
    end
  end

  class Term
    attr_accessor :offset, :length

    def initialize(data, offset, length)
      @data = data
      @offset = offset
      @length = length
    end

    def value
      @data[@offset..(@offset + @length - 1)]
    end

    def is_leaf?
      @data[@offset + @length, 1] != "}"
    end

    def to_s
      "(offset=#{@offset}, length=#{@length}) => #{self.value.inspect} [#{self.is_leaf? ? 'leaf' : 'node'}]"
    end
  end

end
