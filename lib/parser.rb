class KeyNotFoundError < Exception
end

class Parser
  
  attr_reader :data, :offset, :length
  
  def initialize(data, offset=0, length=data.length)
    raise "Invalid data #{data.inspect}" unless data.last == '}'
    @data = data
    @offset = offset
    @length = length
  end
  
  def [](key)
    found = find_key(key)
    # if is_leaf?(found)
    #   return find_value_of(found)
    # else
    #   return create_sub_parser(found)
    # end
    raise "Key #{key.inspect} not found" unless dump[key]
    dump[key]
  end
  
  def find_key(key)
    offset = hash_data.index(':') + 1
    term_type = :first
    
    loop do
      term = next_term(offset)
      term_type = (term_type == :key ? :value : :key)
      if key == term.value && term_type == :key
        return term
      end
      offset = term.offset + term.length + 1
    end
  end
  
  def hash_data
    @data[@offset..@length]
  end
  
  def next_term(offset)
    colon_index = hash_data[offset..-1].index(':')
    raise KeyNotFoundError, "Key not found" unless colon_index

    key_offset = offset + colon_index + 1
    key_length = hash_data[offset..(key_offset - 1)].to_i
    Term.new(hash_data, key_offset, key_length)
  end
  
  private
  
  # TODO remove this method
  def dump
    @dump ||= TNetstring.parse(data).first # TODO
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
  
  def to_s
    "(offset=#{@offset}, length=#{@length}) => #{value}"
  end
end

