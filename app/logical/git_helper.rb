# frozen_string_literal: true

class GitHelper
  include Singleton

  attr_accessor :enabled, :upstream_enabled, :git_exists, :repo_exists, :local, :upstream
  alias enabled? enabled
  alias upstream_enabled? upstream_enabled

  def initialize
    @enabled = false
    @git_exists = system("type git > /dev/null")
    unless @git_exists
      Rails.logger.error("git is not installed")
      return
    end
    @repo_exists = system("git rev-parse --show-toplevel > /dev/null")
    unless @repo_exists
      Rails.logger.error("not in a git repo")
      return
    end

    @enabled = true
    if Rails.env.production?
      @local = Ref.new("internal", "master", FemboyFans.config.local_source_code_url)
      @upstream = Ref.new("upstream", "master", FemboyFans.config.source_code_url)
    else
      branch = `git rev-parse --abbrev-ref HEAD`.strip
      remote = `git config branch.#{branch}.remote`.strip
      @local = Ref.new(remote, branch, FemboyFans.config.source_code_url)
      @upstream = nil
    end
  end

  class Ref
    attr_accessor :remote, :branch, :url, :exists, :hash

    def initialize(remote, branch, url)
      @remote = remote
      @branch = branch
      @url = url

      @exists = system("git show-ref --quiet #{remote}/#{branch}")
      raise(StandardError, "#{remote}/#{branch} does not exist") unless @exists
      return unless @exists
      @hash = `git rev-parse #{remote}/#{branch}`.strip
      raise("Could not get hash for #{remote}/#{branch}") if @hash.blank?
    end

    def short_hash
      @hash&.[](0..7)
    end

    def latest
      return @latest if instance_variable_defined?(:@latest)
      system("git fetch #{remote} #{branch}")
      @latest = `git rev-parse #{remote}/#{branch}`.strip.presence
    end

    def reset_latest
      remove_instance_variable(:@latest)
    end

    def commit_url(commit)
      "#{url}/commit/#{commit}"
    end

    def latest_commit_url
      commit_url(latest)
    end

    def current_commit_url
      commit_url(hash)
    end

    def compare(ref)
      Comparison.new(self, ref)
    end
    alias diff compare

    def ==(other)
      other.is_a?(Ref) && remote == other.remote && branch == other.branch
    end
  end

  class Comparison
    attr_accessor :a, :b

    def initialize(a, b) # rubocop:disable Naming/MethodParameterName
      @a = a
      @b = b
    end

    def common
      @common ||= `git merge-base #{a.hash} #{b.hash}`.strip
    end

    def behind
      @behind ||= `git rev-list --count #{a.hash}..#{b.hash}`.strip.to_i
    end

    def behind?
      behind > 0
    end

    def ahead
      @ahead ||= `git rev-list --count #{b.hash}..#{a.hash}`.strip.to_i
    end

    def ahead?
      ahead > 0
    end

    def ==(other)
      other.is_a?(Comparison) && a == other.a && b == other.b
    end
  end

  def public_ref
    upstream || local
  end

  def common_hash
    upstream.present? ? local.compare(upstream).common : local.hash
  end

  def commit_url(commit)
    "#{local.url}/commit/#{commit}"
  end

  def public_commit_url
    public_ref.commit_url(common_hash)
  end
end
