require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class Parser

    attr_reader :data, :offset, :length

    def initialize(data, offset=0, length=data.length)
      raise "Data is not a Hash: #{data.inspect}" unless data.end_with? Term::Type::DICTIONARY
      @data = data
      @offset = offset
      @length = length
    end

    def [](key)
      begin
        found_key = find_key(key)
      rescue KeyNotFoundError
        return nil
      end

      found_value = term_following found_key
      found_value.value
    end

    def to_s
      "LazyTNetstring::Parser(offset=#{offset}, length=#{length}) => #{data.inspect}"
    end

    private

    def find_key(key)
      offset = hash_data.index(':') + 1
      term = next_term(offset)
      term_type = :key

      loop do
        if key == term.value && term_type == :key
          return term
        end
        offset = term.value_offset + term.length + 1
        term = term_following term # may throw an KeyNotFoundException to abort looping
        term_type = (term_type == :key ? :value : :key)
      end
    end

    def hash_data
      @data[@offset..(@offset + @length)]
    end

    def term_following(term)
      next_term(term.value_offset + term.length + 1)
    end

    def next_term(offset)
      Term.new(hash_data, offset)
    end

  end
end
