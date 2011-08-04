require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class Parser

    attr_reader :data, :offset, :value_offset, :value_length, :length

    def initialize(data, offset=0, length=data.length)
      raise UnsupportedTopLevelDataStructure, "data is not a Hash: #{data.inspect}" unless data.end_with? Term::Type::DICTIONARY
      @data = data
      @offset = offset
      @length = length
      update_indices_and_length
    end

    def [](key)
      term = find_value_term(key)
      term.nil? ? term : term.value
    end

    def []=(key, value)
      term = find_value_term(key)
      old_length = term.length
      term.value = value
      length_delta = term.length - old_length
      new_length = value_length + length_delta
      update_indices_and_length(new_length)
      # TODO: propagate length change up when in nested hashes
      #       should be possible to keep track of outer parsers in a @parents
      #       instance variable
    end

    def to_s
      "LazyTNetstring::Parser(offset=#{offset}, length=#{length}) => #{data.inspect}"
    end

    private

    def find_value_term(key)
      begin
        found_key = find_key(key)
      rescue KeyNotFoundError
        return nil
      end

      term_following(found_key)
    end

    def find_key(key)
      term = first_term
      while term.value != key
        term = term_following term # skip value
        term = term_following term # find next key
      end

      term
    end

    def scoped_data
      data[offset, length]
    end

    def first_term
      term_at(value_offset)
    end

    def term_at(offset)
      Term.new(data, offset)
    rescue InvalidTNetString
      raise KeyNotFoundError
    end

    def term_following(term)
      term_at(term.value_offset + term.length + 1)
    end

    def update_indices_and_length(new_length = nil)
      colon_index = data[offset, 10].index(':')
      raise InvalidTNetString, 'no length found in #{data[offset, 10]}...' unless colon_index
      @value_offset = offset + colon_index + 1
      if new_length
        length_delta = new_length - @value_length
        @value_length = new_length
        @length += length_delta
        data[offset..(value_offset-2)] = new_length.to_s
      else
        @value_length = data[offset..(@value_offset-2)].to_i
      end
    end

  end
end
