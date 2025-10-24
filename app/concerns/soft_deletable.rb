# frozen_string_literal: true

module SoftDeletable
  extend(ActiveSupport::Concern)

  module ClassMethods
    # @param column The database column used to track deletions
    # @param invert If the deletion value should be inverted (if false, true will be used for deletions - if true, false will be used for deletions)
    def soft_deletable(column = :is_deleted, invert: column == :is_active)
      deleted_value = !invert
      scope(:active, -> { where(column => !deleted_value) })
      scope(:not_active, -> { where(column => deleted_value) })
      scope(:deleted, -> { where(column => deleted_value) })
      scope(:not_deleted, -> { where(column => !deleted_value) })

      define_method(:soft_delete) do |**options|
        update(column => deleted_value, **options)
      end

      define_method(:soft_delete_with) do |user, **options|
        update_with(user, column => deleted_value, **options)
      end

      define_method(:soft_delete_with_current) do |*args, **options|
        update_with_current(*args, column => deleted_value, **options)
      end

      define_method(:soft_delete!) do |**options|
        update!(column => deleted_value, **options)
      end

      define_method(:soft_delete_with!) do |user, **options|
        update_with!(user, column => deleted_value, **options)
      end

      define_method(:soft_delete_with_current!) do |*args, **options|
        update_with_current!(*args, column => deleted_value, **options)
      end

      define_method(:soft_undelete) do |**options|
        update(column => !deleted_value, **options)
      end

      define_method(:soft_undelete_with) do |user, **options|
        update_with(user, column => !deleted_value, **options)
      end

      define_method(:soft_undelete_with_current) do |*args, **options|
        update_with_current(*args, column => !deleted_value, **options)
      end

      define_method(:soft_undelete!) do |**options|
        update!(column => !deleted_value, **options)
      end

      define_method(:soft_undelete_with!) do |user, **options|
        update_with!(user, column => !deleted_value, **options)
      end

      define_method(:soft_undelete_with_current!) do |*args, **options|
        update_with_current!(*args, column => !deleted_value, **options)
      end
    end
  end
end
