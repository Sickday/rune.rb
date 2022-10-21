module RuneRb::Utils::Trapping
  def setup_trapping(&_)
    Signal.trap('INT') do
      Thread.new do
        log 'Caught interrupt signal! Shutting down'
        yield if block_given?
      ensure
        shutdown
        exit!
      end
    end

    Signal.trap('TERM') do
      Thread.new do
        log 'Caught interrupt signal! Shutting down'
        yield if block_given?
      ensure
        shutdown
        exit!
      end
    end
  end
end
