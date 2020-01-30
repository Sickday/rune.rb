module RSRS
  module Models
    class Item < Sequel::Model

      def high_alch
        (self[:basevalue] * 0.6).to_i
      end

      def low_alch
        (self[:basevalue] * 0.4).to_i
      end
    end
  end
end