#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

Post.document_store.create_index!(delete_existing: true)
Post.document_store.import
PostVersion.document_store.create_index!(delete_existing: true)
PostVersion.document_store.import
