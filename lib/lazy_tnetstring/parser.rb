require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class Parser

    attr_reader :data, :offset, :value_offset, :value_length, :length, :scope_chain

    def initialize(data, offset=0, length=data.length, scope_chain=nil, scoped=false)
      raise UnsupportedTopLevelDataStructure, "data is not a Hash: #{data.inspect}" unless data.end_with? Term::Type::DICTIONARY
      @data        = data
      @offset      = offset
      @length      = length
      @scope_chain = scope_chain
      @scope_chain ||= [self]
      @scope_chain.unshift(self) if scoped
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

      scope_chain.each do |parser|
        additional_length_delta = parser.update_indices_and_length(length_delta)
        length_delta += additional_length_delta
      end
    end

    def to_s
      "#<LazyTNetstring::Parser:#{object_id} @offset=#{offset.inspect} @length=#{length.inspect} @data=#{data.inspect}>"
    end

    protected

    def update_indices_and_length(length_delta = nil)
      if length_delta
        @value_length += length_delta
        @length += length_delta
        data[offset..(value_offset-2)] = value_length.to_s
        old_value_offset = value_offset
        update_value_offset
        additional_length_delta = value_offset - old_value_offset
        @length += additional_length_delta
      else
        update_value_offset
        @value_length = data[offset..(@value_offset-2)].to_i
        additional_length_delta = nil
      end

      additional_length_delta
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
      Term.new(data, offset, scope_chain)
    rescue InvalidTNetString
      raise KeyNotFoundError
    end

    def term_following(term)
      term_at(term.value_offset + term.value_length + 1)
    end

    def update_value_offset
      colon_index = data[offset, 10].index(':')
      raise InvalidTNetString, 'no length found in #{data[offset, 10]}...' unless colon_index
      @value_offset = offset + colon_index + 1
    end

  end
end
