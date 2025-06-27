# frozen_string_literal: true

module Revertible
  extend(ActiveSupport::Concern)
  class RevertError < StandardError; end

  module ClassMethods
    def revertible(options = {}, &block)
      raise(ArgumentError, "missing block") if block.blank?
      raise(ArgumentError, "invalid block") if block.arity != 1
      cattr_accessor(:revertible_updater_column, :revertible_versionable_column, :revertible_block)
      self.revertible_updater_column = options[:revertible_updater_column] || "updater"
      self.revertible_versionable_column = options[:revertible_versionable_column] || "#{name.underscore}_id"
      self.revertible_block = block

      class_eval do
        def revert_to(version)
          if id != version.send(self.class.revertible_versionable_column)
            raise(RevertError, "You cannot revert to a previous version of another #{self.class.model_name.human.downcase}.")
          end
          instance_exec(version, &self.class.revertible_block)
        end

        def revert_to!(version, user)
          revert_to(version)
          send("#{self.class.revertible_updater_column}=", user)
          save!
        end
      end
    end
  end
end
