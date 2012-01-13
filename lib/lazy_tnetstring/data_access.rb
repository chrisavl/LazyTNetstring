require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  class DataAccess

    attr_reader :data, :offset, :term, :parent, :children, :scope

    def initialize(data, offset=0, parent=nil, scope=nil)
      @data       = data
      @parent     = parent
      @children   = []
      @scope      = scope
      @dangling   = false
      self.offset = offset
      raise UnsupportedTopLevelDataStructure, "data is not a Hash: #{data.inspect}" unless term.type == Term::Type::DICTIONARY

      parent.add_child(self) if parent
    end

    def [](key)
      raise LazyTNetstring::InvalidScope if dangling?
      value_term = find_value_term(key)
      value_term.nil? ? value_term : value_term.value
    end

    def []=(key, value)
      raise LazyTNetstring::InvalidScope if dangling?
      return remove(key) if value.nil?

      value_term = find_value_term(key)
      old_length = value_term.length
      value_term.value = value
      length_delta = value_term.length - old_length

      update_tree(length_delta) if length_delta != 0
    end

    def remove(key)
      begin
        found_key = find_key(key)
        found_value = term_following(found_key)
        del_length = found_key.length + found_value.length
        del_begin = found_key.offset
        del_end = del_begin + del_length
        data[del_begin..(del_end-1)] = ''

        update_tree(-del_length)
      rescue KeyNotFoundError
      end
    end

    def scoped_data
      raise LazyTNetstring::InvalidScope if dangling?
      data[offset, term.length]
    end

    def dangling?
      !!@dangling
    end

    def to_s
      "#<LazyTNetstring::DataAccess:#{object_id} @scope=#{scope.inspect} @dangling=#{dangling.inspect} @offset=#{offset.inspect} @data=#{data.inspect}(len=#{data.length}) parent=#{parent.object_id} children=#{children.map(&:object_id).inspect}(count=#{children.size})>"
    end

    protected

    attr_writer :dangling

    def add_child(data_access)
      @children << data_access
    end

    def update_tree(length_delta)
      old_value_offset = term.value_offset
      term.value_length += length_delta
      additional_length_delta = term.value_offset - old_value_offset
      if parent
        parent.update_tree(length_delta + additional_length_delta)
      else
        self.offset = offset # reached root, now propagate offset update to children
      end
    end

    def offset=(new_offset)
      @offset = new_offset
      @term = Term.new(data, new_offset, parent, scope)

      children.each do |child|
        begin
          child.offset = value_offset_for_key(child.scope)
        rescue KeyNotFoundError
          # the scope is no longer valid, it must have been
          # replaced with new content at a higher level
          child.dangling = true
        end
      end
      children.delete_if(&:dangling?)
    end

    private

    def value_offset_for_key(key)
      term_following(find_key(key)).offset
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
