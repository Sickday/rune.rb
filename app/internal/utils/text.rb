module RuneRb::Utils::Text
  FREQUENCY_ORDERED_CHARS = [' ', 'e', 't', 'a', 'o', 'i', 'h', 'n', 's', 'r', 'd', 'l',
                             'u', 'm', 'w', 'c', 'y', 'f', 'g', 'p', 'b', 'v', 'k', 'x', 'j', 'q', 'z', '0', '1', '2', '3', '4', '5',
                             '6', '7', '8', '9', ' ', '!', '?', '.', ',', ':', ';', '(', ')', '-', '&', '*', '\\', '\'', '@', '#', '+',
                             '=', '\243', '$', '%', '"', '[', ']'].freeze
  # Compress a string
  # @param input [String] the string to compress
  def compress(input)
    out = []
    input = input.slice!(80)&.downcase!
    return if input.nil?

    carry = -1
    input.chars.each do |char|
      table_idx = FREQUENCY_ORDERED_CHARS.index(char) || 0
      table_idx += 195 if table_idx > 12

      if carry == -1
        table_idx < 13 ? carry = table_idx : out << table_idx
      elsif table_idx < 13
        out << ((carry << 4) + table_idx)
        carry = -1
      else
        out << ((carry << 4) + (table_idx >> 4))
        carry = table_idx & 0xF
      end
    end
    out << (carry << 4) if carry == -1
    out
  end


  def decompress(input)
    out = []
    carry = -1

  end
end