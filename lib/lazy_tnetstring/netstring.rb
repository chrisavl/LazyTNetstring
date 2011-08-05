require 'lazy_tnetstring/exceptions'

module LazyTNetstring
  module Netstring

    def value_offset_for(data, offset)
      colon_index = data[offset, 10].index(':')
      raise InvalidTNetString, "no length found in #{data[offset, 10]}..." unless colon_index
      offset + colon_index + 1
    end

  end
end
