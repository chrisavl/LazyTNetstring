require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class DataAccess

    attr_reader :data, :offset, :term, :parent, :children, :scope

    def initialize(data, offset=0, parent=nil, scope=nil)
      @term     = Term.new(data, offset, parent, scope)
      raise UnsupportedTopLevelDataStructure, "data is not a Hash: #{data.inspect}" unless term.type == Term::Type::DICTIONARY
      @data     = data
      @offset   = offset
      @parent   = parent
      @children = []
      @scope    = scope

      update_indices_and_length
      parent.add_child(self) if parent
    end

    def [](key)
      value_term = find_value_term(key)
      value_term.nil? ? value_term : value_term.value
    end

    def []=(key, value)
      value_term = find_value_term(key)
      old_length = value_term.length
      value_term.value = value
      length_delta = value_term.length - old_length

      propagate_length_update(length_delta)
    end

    def to_s
      "#<LazyTNetstring::DataAccess:#{object_id} @scope=#{scope.inspect} @offset=#{offset.inspect} @data=#{data.inspect}(len=#{data.length}) parent=#{parent.object_id} children=#{children.map(&:object_id).inspect}(count=#{children.size})>"
    end

    protected

    def scoped_data
      data[offset, term.length]
    end

    def add_child(data_access)
      @children << data_access
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

      children.each do |child|
        child.propagate_offset_update
      end
    end

    def value_offset_for_key(key)
      find_value_term(key).offset
    end

    private

    def offset=(new_offset)
      @offset = new_offset
      @term = Term.new(data, new_offset, parent, scope)
    end

    def update_indices_and_length(length_delta = nil)
      if length_delta
        old_value_offset = term.value_offset
        term.value_length += length_delta
        additional_length_delta = term.value_offset - old_value_offset
      else
        # @value_offset = value_offset_for(data, offset)
        # @value_length = data[offset..(@value_offset-2)].to_i
        additional_length_delta = nil
      end

      additional_length_delta
    end

    def find_value_term(key)
      begin
        found_key = find_key(key)
      rescue KeyNotFoundError
        return nil
      end

      term_following(found_key)
    end

    def find_key(key)
      current_term = first_term(key)
      while current_term.value != key
        current_term = term_following current_term # skip value
        current_term = term_following current_term # find next key
      end

      current_term
    end

    def first_term(new_scope)
      term_at(term.value_offset, new_scope)
    end

    def term_at(offset, new_scope)
      Term.new(data, offset, self, new_scope)
    rescue InvalidTNetString
      raise KeyNotFoundError
    end

    def term_following(term)
      term_at(term.offset + term.length, term.scope)
    end

  end
end
