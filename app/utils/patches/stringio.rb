module RuneRb::Utils::Patches::StringIORefinements
  refine StringIO do

    # Flips the underlying data.
    def reverse
      current = string
      string = current.reverse!
    end

    def [](index)
      string[index]
    end

    def []=(index, value)
      current = string
      new_str = string[index] = value
      string = new_str
    end
  end
end