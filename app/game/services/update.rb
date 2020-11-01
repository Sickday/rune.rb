module RuneRb::Game::Services
  class UpdateService
    include RuneRb::Types::Loggable
    include RuneRb::Types::Service

    attr :current_requests, :cached_update

    def request(entity)
      @current_requests ||= {}
    end

    def dispatch

    end

    private

    # Logic for the update service is executed
    def execute
      loop do
        next if @current_requests.empty?


      end
    end

    def process_requests
      #

    end
  end
end