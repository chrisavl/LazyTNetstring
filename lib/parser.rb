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
    offset = 0
    colon_index = hash_data[(0+offset)..(-1-offset)].index(':')
    data_length = hash_data[(0+offset)..(colon_index-offset)].to_i
    
    loop do
      offset = data_length.to_s.length + 1
      colon_index = @data[(@offset+offset)..(@length-offset)].index(':')
      data_length = @data[@offset+offset..colon_index-offset].to_i
    
      key_start = @offset+offset+colon_index.to_s.length+1
      next_key = @data[key_start..(key_start+data_length-1)]

      if key == next_key
        l = Location.new
        l.offset = key_start
        l.length = data_length
        return l
      end
      offset = key_start + data_length
      if data_length == 0
        raise "Key #{key.inspect} not found"
      end
# puts "key=#{key}, data_length=#{data_length}, next_key=#{next_key}, offset=#{offset}, key_start=#{key_start}"
    end
  end
  
  def hash_data
    @data[@offset..@length]
  end
  
  private
  
  def dump
    @dump ||= TNetstring.parse(data).first # TODO
  end
end

class Location
  attr_accessor :offset, :length
end

