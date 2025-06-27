# frozen_string_literal: true

module TraceLogger
  module_function

  COLORS = {
    black:   "\e[30m",
    red:     "\e[31m",
    green:   "\e[32m",
    yellow:  "\e[33m",
    blue:    "\e[34m",
    magenta: "\e[35m",
    cyan:    "\e[36m",
    white:   "\e[37m",
    reset:   "\e[0m",
  }.freeze

  # noinspection RubyLiteralArrayInspection
  LEVELS = {
    debug:   ["%<cyan>s", "%<blue>s"],
    error:   ["%<red>s", "%<red>s"],
    info:    ["%<cyan>s", "%<blue>s"],
    warn:    ["%<yellow>s", "%<yellow>s"],
    default: ["%<white>s", "%<white>s"],
  }.freeze

  def format_level(level)
    level = level.to_sym
    primary, alternate = LEVELS.fetch(level, LEVELS[:default])
    colorize("#{alternate}[%<reset>s#{primary}#{level.to_s.upcase}%<reset>s#{alternate}]%<reset>s")
  end

  def colorize(text, **)
    format(text, **COLORS, **)
  end

  def debug(*, **)
    _log(*, level: :debug, **)
  end

  def error(*, **)
    _log(*, level: :error, **)
  end

  def info(*, **)
    _log(*, level: :info, **)
  end

  def warn(*, **)
    _log(*, level: :warn, **)
  end

  def _log(*arg, ignore: nil, level: :log, lines: 3, format: nil)
    return unless Rails.logger.public_send("#{level}?")
    if arg.one?
      name = nil
      message = arg.first
    else
      name = arg.shift
      message = arg.join
    end
    primary, alternate = LEVELS.fetch(level, LEVELS[:default])
    args = { level: format_level(level), name: name, message: message }
    fmt = "%<level>s"
    if format.nil?
      if name.present?
        fmt += " #{alternate}[%<reset>s%<magenta>s%<name>s%<reset>s#{alternate}]%<reset>s #{primary}%<message>s%<reset>s"
      else
        fmt += " #{primary}%<message>s%<reset>s"
      end
    else
      fmt += " #{format}%<reset>s"
    end
    ignore = Array(ignore).unshift(%r{/logical/trace_logger\.rb})
    callers = caller_locations.reject do |loc|
      path = loc.absolute_path || loc.path
      !Rails.backtrace_cleaner.clean_frame("#{path}:#{loc.lineno}") || ignore.any? { |i| path.match?(i) }
    end
    callers = callers.take(lines) if lines.present?
    Rails.logger.public_send(level, colorize(fmt, **args))
    callers.each { |c| Rails.logger.public_send(level, "↳ #{c.path.gsub(%r{^/app/}, '')}:#{c.lineno} in `#{c.label}`") }
  end

  private_class_method(:_log)
end
