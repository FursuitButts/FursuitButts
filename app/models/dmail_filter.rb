class DmailFilter < ApplicationRecord
  extend Memoist

  belongs_to :user
  validates :user, presence: true
  before_validation :initialize_user
  validates :words, length: { maximum: Danbooru.config.dmail_maximum_words }

  def initialize_user
    unless user_id
      self.user_id = CurrentUser.user.id
    end
  end

  def filtered?(dmail)
    dmail.from.level < User::Levels::MODERATOR && has_filter? && (dmail.body =~ regexp || dmail.title =~ regexp || dmail.from.name =~ regexp)
  end

  def has_filter?
    !words.strip.empty?
  end

  def regexp
    union = words.split(/[[:space:]]+/).map { |word| Regexp.escape(word) }.join("|")
    /\b#{union}\b/i
  end

  memoize :regexp
end
