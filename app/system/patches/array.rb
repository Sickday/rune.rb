module RuneRb::System::Patches::ArrayOverrides
  using RuneRb::System::Patches::IntegerOverrides
  refine Array do
    def unpack_txt
      chars = [
        ' ', 'e', 't', 'a', 'o', 'i', 'h', 'n', 's', 'r', 'd', 'l', 'u',
        'm', 'w', 'c', 'y', 'f', 'g', 'p', 'b', 'v', 'k', 'x', 'j', 'q',
        'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '!',
        '?', '.', ',', ':', ';', '(', ')', '-', '&', '*', '\\', '\'', '@',
        '#', '+', '=', '\243', '$', '%', '"',	'[', ']'
      ]
      decode = Array.new(4096, 0)
      index = 0
      after = -1

      length.times do
        value = shift.to_i
        char_idx = value >> 4 & 0xf

        if after == -1
          if char_idx < 13
            self[index += 1] = chars[char_idx]
          else
            after = char_idx
          end
        else
          self[index += 1] == chars[((after << 4) + char_idx) - 195]
        end

        char_idx = value & 0xf
        if after == -1
          if char_idx < 13
            self[index += 1] = chars[char_idx]
          else
            after = char_idx
          end
        else
          self[index += 1] = chars[((after << 4) + char_idx) - 195]
        end
      end

=begin
      capital = true
      index.times do |count|
        char = self[count]
        if capital && char >= 'a' && char <= 'z'
          self[count] += '\uFFE0'
          capital = false
        end
        capital = true if %w[. ! ?].include?(char)
      end
=end
      join(' ')
    end
  end
end