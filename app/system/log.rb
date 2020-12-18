module RuneRb::System::Log
  # Gets this class' name.
  def class_name
    self.class.name.split('::').last.to_sym
  end

  ##
  # Log info lines
  # @param lines [Array] lines of text that are passed to the logger.
  def log(*lines)
    lines.each do |line|
      RuneRb::LOG_FILE.info(RuneRb::COL.strip("[#{Time.now.strftime('[%H:%M')}] #{line}"))
      RuneRb::LOG.info(RuneRb::COL.white("[#{class_name}] -> #{line}"))
    end
    nil
  end

  ##
  # Log debug lines
  # @param lines [Array] lines of text that are passed to the logger.
  def debug(*lines)
    lines.each do |line|
      RuneRb::LOG_FILE.debug(RuneRb::COL.strip("[#{Time.now.strftime('[%H:%M')}] #{line}"))
      RuneRb::LOG.debug("[#{class_name}] -> #{line}")
    end
  end

  ##
  # Log warning lines
  # @param lines [Array] lines of text that are passed to the logger.
  def log!(*lines)
    lines.each do |line|
      RuneRb::LOG_FILE.warn(RuneRb::COL.strip("[#{Time.now.strftime('[%H:%M')}] #{line}"))
      RuneRb::LOG.warn(RuneRb::COL.yellow("[#{class_name}] -> #{line}"))
    end
    nil
  end

  ##
  # Log error lines
  # @param lines [Array] lines of text that are passed to the logger.
  def err(*lines)
    lines.each do |line|
      RuneRb::LOG_FILE.error(RuneRb::COL.strip("[#{Time.now.strftime('[%H:%M')}] #{line}"))
      RuneRb::LOG.error(RuneRb::COL.magenta.bold("[#{class_name}] ~> #{line}"))
    end
    nil
  end

  ##
  # Log fatal lines
  # @param lines [Array] lines of text that are passed to the logger.
  def err!(*lines)
    lines.each do |line|
      RuneRb::LOG_FILE.fatal(RuneRb::COL.strip("[#{Time.now.strftime('[%H:%M')}] #{line}"))
      RuneRb::LOG.error(RuneRb::COL.red.bold("[#{class_name}] ~> #{line}"))
    end
    nil
  end

  # Returns the file name as a symbol.
  # @param string [String] The path to the file.
  def symbolize_file(string)
    File.basename(string, '*.rb').to_sym
  end
end