module RuneRb::Types::Service
  # Run the service. Will execute the Service#execute function in a separate Thread.
  # @return [Thread] the worker thread.
  def run
    @worker = Thread.start { execute }
  end

  # Stops the Service#worker thread via Thread#terminate
  def stop
    Thread.terminate(@worker)
  end

  # Kills the Service#worker thread via Thread.kill
  def kill
    Thread.kill(@worker)
  end

  private

  # Task this service is going to perform on it's worker thread.
  def execute; end
end