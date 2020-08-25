module Scratch::Utils
  # Gets this class' name.
  def class_name
    self.class.name.split('::').last.to_sym
  end

  ##
  # Log info lines
  # @param lines [Array] lines of text that are passed to the logger.
  def log(*lines)
    lines.each do |line|
      Scratch::LOG_FILE.info(line)
      Scratch::LOG.info(Scratch::COL.green("[#{Time.now.strftime('[%H:%M')}]:[#{class_name}] ~> #{line}"))
    end
    nil
  end

  ##
  # Log warning lines
  # @param lines [Array] lines of text that are passed to the logger.
  def log!(*lines)
    lines.each do |line|
      Scratch::LOG_FILE.warn(line)
      Scratch::LOG.warn(Scratch::COL.yellow("[#{Time.now.strftime('[%H:%M')}]:[#{class_name}] ~> #{line}"))
    end
    nil
  end

  ##
  # Log error lines
  # @param lines [Array] lines of text that are passed to the logger.
  def err(*lines)
    lines.each do |line|
      Scratch::LOG_FILE.error(line)
      Scratch::LOG.error(Scratch::COL.magenta.bold("[#{Time.now.strftime('[%H:%M:')}]:[#{class_name}] ~> #{line}"))
    end
    nil
  end

  ##
  # Log fatal lines
  # @param lines [Array] lines of text that are passed to the logger.
  def err!(*lines)
    lines.each do |line|
      Scratch::LOG_FILE.fatal(line)
      Scratch::LOG.error(Scratch::COL.red.bold("[#{Time.now.strftime('[%H:%M')}]:[#{class_name}] ~> #{line}"))
    end
    nil
  end

  # Returns the file name as a symbol.
  # @param string [String] The path to the file.
  def symbolize_file(string)
    File.basename(string, '*.rb').to_sym
  end
end