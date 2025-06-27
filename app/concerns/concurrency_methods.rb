# frozen_string_literal: true

module ConcurrencyMethods
  extend(ActiveSupport::Concern)

  class_methods do
    def parallel_find_each(**options, &block)
      # XXX We may deadlock if a transaction is open; do a non-parallel each.
      return find_each(&block) if connection.transaction_open?

      find_in_batches(error_on_ignore: true, **options) do |batch|
        batch.parallel_each(&block)
      end
    end
  end
end
