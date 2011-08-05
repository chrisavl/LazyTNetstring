require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class DataAccess

    attr_reader :data, :offset, :value_offset, :value_length, :length, :parent, :children, :scope

    def initialize(data, offset=0, length=data.length, parent=nil, scope=nil)
      raise UnsupportedTopLevelDataStructure, "data is not a Hash: #{data.inspect}" unless data.end_with? Term::Type::DICTIONARY
      @data     = data
      @offset   = offset
      @length   = length
      @parent   = parent
      @children = []
      @scope    = scope

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

      propagate_length_update(length_delta)
    end

    def add_child(data_access)
      @children << data_access
    end

    def to_s
      "#<LazyTNetstring::DataAccess:#{object_id} @scope=#{scope.inspect} @offset=#{offset.inspect} @length=#{length.inspect} @data=#{data.inspect}(len=#{data.length}) parent=#{parent.object_id} children=#{children.map(&:object_id).inspect}(count=#{children.size})>"
    end

    protected

    def scoped_data
      data[offset, length]
    end

    def propagate_length_update(length_delta)
      additional_length_delta = update_indices_and_length(length_delta)
      if parent
        parent.propagate_length_update(length_delta + additional_length_delta)
      else
        propagate_offset_update # reached root, now propagate offset update to all children
      end
    end

    def propagate_offset_update
      self.offset = parent.value_offset_for_key(scope) if parent
      update_value_offset

      children.each do |child|
        child.propagate_offset_update
      end
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
      Term.new(data, offset, self, new_scope)
    rescue InvalidTNetString
      raise KeyNotFoundError
    end

    def term_following(term)
      term_at(term.value_offset + term.value_length + 1, term.scope)
    end

  end
end
