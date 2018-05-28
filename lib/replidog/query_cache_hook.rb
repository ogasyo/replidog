module Replidog
  # Based on ActiveRecord::QueryCache
  # @see https://github.com/rails/rails/blob/v5.1.6/activerecord/lib/active_record/query_cache.rb
  #
  class QueryCacheHook

    def self.run
      ActiveRecord::Base.proxy_handler.all_slave_connection_pools.
        reject { |p| p.query_cache_enabled }.each { |p| p.enable_query_cache! }
    end

    def self.complete(pools)
      pools.each { |pool| pool.disable_query_cache! }

      ActiveRecord::Base.proxy_handler.all_slave_connection_pools.each do |pool|
        pool.release_connection if pool.active_connection? && !pool.connection.transaction_open?
      end
    end

    def self.install_executor_hooks(executor = ActiveSupport::Executor)
      executor.register_hook(self)
    end

  end
end

ActiveSupport.on_load(:active_record) do
  Replidog::QueryCacheHook.install_executor_hooks
end
