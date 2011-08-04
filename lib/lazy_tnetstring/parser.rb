require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class Parser

    attr_reader :data, :offset, :value_offset, :length

    def initialize(data, offset=0, length=data.length)
      raise UnsupportedTopLevelDataStructure, "data is not a Hash: #{data.inspect}" unless data.end_with? Term::Type::DICTIONARY
      @data = data
      @offset = offset
      @length = length
      colon_index = hash_data.index(':')
      raise InvalidTNetString, 'no length found in #{data[offset, 12]}...' unless colon_index
      @value_offset = colon_index + 1
    end

    def [](key)
      begin
        found_key = find_key(key)
      rescue KeyNotFoundError
        return nil
      end

      term_following(found_key).value
    end

    def to_s
      "LazyTNetstring::Parser(offset=#{offset}, length=#{length}) => #{data.inspect}"
    end

    private

    def find_key(key)
      term = first_term

      while term.value != key
        term = term_following term # skip value
        term = term_following term # find next key
      end

      term
    end

    def hash_data
      data[offset, length+1]
    end

    def first_term
      term_at(value_offset)
    end

    def term_at(offset)
      Term.new(hash_data, offset)
    rescue InvalidTNetString
      raise KeyNotFoundError
    end

    def term_following(term)
      term_at(term.value_offset + term.length + 1)
    end

  end
end
