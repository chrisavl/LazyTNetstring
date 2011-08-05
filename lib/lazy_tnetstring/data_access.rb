require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class DataAccess

    attr_reader :data, :offset, :value_offset, :value_length, :length, :scope_chain, :scope

    def initialize(data, offset=0, length=data.length, scope_chain=nil, scope=nil)
      raise UnsupportedTopLevelDataStructure, "data is not a Hash: #{data.inspect}" unless data.end_with? Term::Type::DICTIONARY
      @data        = data
      @offset      = offset
      @length      = length
      @scope_chain = scope_chain
      @scope_chain ||= [self]

      if scope
        @scope_chain.unshift(self)
        @scope = scope
      end

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
      puts "\nupdating all elements in the scope chain"
      scope_chain.each do |data_access|
        additional_length_delta = data_access.update_indices_and_length(length_delta)
        puts "updating indices and length with delta=#{length_delta} for data_access #{data_access}, additional_length_delta=#{additional_length_delta}"
        length_delta += additional_length_delta
      end

      parent = nil
      scope_chain.reverse.each do |data_access|
        if data_access.scope && parent
          puts "adjusting offset of #{data_access} for scope #{scope.inspect} to #{parent.value_offset_for_key(scope)}"
          data_access.offset = parent.value_offset_for_key(scope)
          data_access.update_value_offset
          puts "#{data_access}'s scoped data now starts with #{data_access.scoped_data[0, 20]}..."
        end
        parent = data_access
      end
    end

    def to_s
      "#<LazyTNetstring::DataAccess:#{object_id} @scope=#{scope.inspect} @offset=#{offset.inspect} @length=#{length.inspect} @data=#{data.inspect}(len=#{data.length})>"
    end

    protected

    def scoped_data
      data[offset, length]
    end

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

    def update_value_offset
      colon_index = data[offset, 10].index(':')
      raise InvalidTNetString, "no length found in #{data[offset, 10]}..." unless colon_index
      @value_offset = offset + colon_index + 1
    end

    def value_offset_for_key(key)
      find_value_term(key).offset
    end

    def offset=(offset)
      @offset = offset
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
      term = first_term(key)
      while term.value != key
        term = term_following term # skip value
        term = term_following term # find next key
      end

      term
    end

    def first_term(new_scope)
      term_at(value_offset, new_scope)
    end

    def term_at(offset, new_scope)
      Term.new(data, offset, scope_chain, new_scope)
    rescue InvalidTNetString
      raise KeyNotFoundError
    end

    def term_following(term)
      term_at(term.value_offset + term.value_length + 1, term.scope)
    end

  end
end
