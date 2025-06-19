# frozen_string_literal: true

module BulkUpdateRequestCommands
  class ProcessingError < StandardError; end
  MAX_CONSECUTIVE_EMPTY_LINES = 1
  MAX_CONSECUTIVE_COMMENTS = 2
  MAX_EMPTY_LINES = 10
  MAX_COMMENTS = 10

  module_function

  def all
    constants.select do |name|
      value = const_get(name)
      next false unless value.is_a?(Class)
      next false unless value < Base
      next false if value == Invalid
      true
    end.map { |name| const_get(name) }
  end

  def find_by_command(command)
    all.find { |cmd| cmd.command == command } || Invalid
  end

  def parse_line(line)
    line = line.gsub(/[[:space:]]+/, " ").strip
    cmd = all.find { |c| c.matches?(line) }
    cmd = Invalid if cmd.blank?
    cmd.new(*cmd.tokenize(line))
  end

  # noinspection RubyUnnecessaryReturnValue
  def parse(text)
    commands = text.split(/\r?\n/).map { |line| parse_line(line) }
    commands = remove_excessive_commands(commands, MAX_EMPTY_LINES, EmptyLine.command, get: :command, merge: nil, consecutive: false, tokenized: false)
    commands = remove_excessive_commands(commands, MAX_COMMENTS, Comment.command, get: :command, merge: :merge_comment!, consecutive: false, tokenized: false)
    commands = remove_excessive_commands(commands, MAX_CONSECUTIVE_EMPTY_LINES, EmptyLine.command, get: :command, merge: nil, consecutive: true, tokenized: false)
    commands = remove_excessive_commands(commands, MAX_CONSECUTIVE_COMMENTS, Comment.command, get: :command, merge: :merge_comment!, consecutive: true, tokenized: false)
    commands = trim_start_end(commands, EmptyLine.command, get: :command)
    commands
  end

  def tokenize_line(line)
    line = line.gsub(/[[:space:]]+/, " ").strip
    cmd = all.find { |c| c.matches?(line) }
    cmd = Invalid if cmd.blank?
    [cmd.command, *cmd.tokenize(line)]
  end

  # noinspection RubyUnnecessaryReturnValue
  def tokenize(text)
    tokens = text.split(/\r?\n/).map { |line| tokenize_line(line) }
    tokens = remove_excessive_commands(tokens, MAX_EMPTY_LINES, EmptyLine.command, get: :first, merge: nil, consecutive: false, tokenized: true)
    tokens = remove_excessive_commands(tokens, MAX_COMMENTS, Comment.command, get: :first, merge: :merge_comment!, consecutive: false, tokenized: true)
    tokens = remove_excessive_commands(tokens, MAX_CONSECUTIVE_EMPTY_LINES, EmptyLine.command, get: :first, merge: nil, consecutive: true, tokenized: true)
    tokens = remove_excessive_commands(tokens, MAX_CONSECUTIVE_COMMENTS, Comment.command, get: :first, merge: :merge_comment!, consecutive: true, tokenized: true)
    tokens = trim_start_end(tokens, EmptyLine.command, get: :first)
    tokens
  end

  def untokenize_line(command, *args, comments: true)
    cmd = all.find { |c| c.command == command }
    cmd = Invalid if cmd.blank?
    args[-1] = nil if cmd.has_comment? && !comments
    cmd.untokenize(*args)
  end

  def untokenize(tokens, comments: true)
    tokens.map { |token| untokenize_line(*token, comments: comments) }.join("\n")
  end

  def line_to_dtext(command, *)
    cmd = all.find { |c| c.command == command }
    cmd = Invalid if cmd.blank?
    cmd.to_dtext(*)
  end

  def to_dtext(tokens)
    tokens.map { |token| line_to_dtext(*token) }.join("\n")
  end

  def remove_excessive_commands(tokens, limit, command, get:, merge: nil, consecutive: true, tokenized: false)
    result = []
    found = 0
    tokens.each do |token|
      if token.public_send(get) == command
        found += 1
        if found > limit
          prev = result.select { |r| r.public_send(get) == command }.last
          if merge && prev
            index = result.index(prev)
            if tokenized
              a = find_by_command(command).new(*prev[1..])
              b = find_by_command(command).new(*token[1..])
              c = a.public_send(merge, b)
              result[index] = [command, *c.tokenized]
            else
              result[index] = prev.public_send(merge, token)
            end
          end
        else
          result.push(token)
        end
      else
        found = 0 if consecutive
        result.push(token)
      end
    end
    result
  end

  def trim_start_end(tokens, command, get:)
    start_index = tokens.find_index { |token| token.public_send(get) != command } || tokens.size
    trimmed = tokens[start_index..] || []

    end_index = trimmed.rindex { |token| token.public_send(get) != command } || -1
    trimmed[0..end_index] || []
  end

  private_class_method(:remove_excessive_commands)
  private_class_method(:trim_start_end)
end
