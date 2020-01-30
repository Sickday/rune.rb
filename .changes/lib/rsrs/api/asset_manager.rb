module RSRS
  module API
    class AssetManager

      ASSETS = {}

      ##
      # Shorthand for asset retrieval.
      def [](key)
        ASSETS[key]
      end

      private

      ##
      # Loads resources into this Manager.
      def load_resources; end
    end
  end
end