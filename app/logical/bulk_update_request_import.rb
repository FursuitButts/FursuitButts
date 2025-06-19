# frozen_string_literal: true

class BulkUpdateRequestImport
  class Error < StandardError; end
  attr_reader(:forum_topic, :creator, :ip_addr, :processor)

  delegate(:valid?, :validate!, :errors, to: :processor)

  def initialize(script, forum_topic, creator, ip_addr)
    @script = script
    @forum_topic = forum_topic
    @creator = creator
    @ip_addr = ip_addr
    @processor = BulkUpdateRequestProcessor.new(script, forum_topic.presence, creator: creator, ip_addr: ip_addr)
  end

  def script
    @processor.script_with_comments_and_errors
  end

  def queue
    BulkUpdateRequestImportJob.perform_later(@script, @forum_topic, @creator, @ip_addr)
  end

  def process!
    @processor.process!(@creator)
  end
end
