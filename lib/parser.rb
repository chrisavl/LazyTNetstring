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
  
  # 
  def find_key(key)
    key_offset, key_length = next_term(0)
    
    loop do
      offset = key_length.to_s.length + 1
      key_offset, key_length = next_term(offset)
    
      next_key = hash_data[key_offset..(key_offset + key_length - 1)]
puts "key=#{key}, key_length=#{key_length}, next_key=#{next_key}, offset=#{offset}, key_offset=#{key_offset}"

      if key == next_key
        return Location.new(key_offset, key_length)
      end
      offset = key_offset + key_length + 1
      if key_length == 0
        raise "Key #{key.inspect} not found"
      end
    end
  end
  
  def hash_data
    @data[@offset..@length]
  end
  
  def next_term(offset)
    colon_index = hash_data[offset..(-1 - offset)].index(':') + offset
    key_offset = colon_index + 1
    key_length = hash_data[offset..colon_index].to_i
# puts "offset=#{offset}, colon_index=#{colon_index}, key_offset=#{key_offset}, key_length=#{key_length} => hash_data[#{key_offset}..#{key_length}]=#{hash_data[key_offset..key_length]}"
    [key_offset, key_length]
  end

  private
  
  def dump
    @dump ||= TNetstring.parse(data).first # TODO
  end
end

class Location
  attr_accessor :offset, :length
  
  def initialize(offset, length)
    @offset = offset
    @length = length
  end
end

