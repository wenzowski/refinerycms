##
# Injects Rack::Cache into the stack with appropriate settings for all
# environments
#
# Production Use
# ==============
#
# While ActiveSupport::Cache::MemoryStore is threadsafe, it won't share cache
# data between server processes. Disk storage will allow multiple processes to
# share cache state, while a distributed memory cache like memcached will allow
# multiple nodes to share it.
#
# Disk Storage
# ------------
# The default disk storage will grow until the disk is full unless old entries
# are deleted periodically. This is not an issue for providers with ephemeral
# filesystems like Heroku's Cedar stack.
#
# Each cache must have a different path to prevent collisions.
#
# Memcached
# ---------
# In production, a memcached instance is a good way to store the frequently-
# accessed MetaStore, which will reduce the overall latency of the cache. It is
# inadvisable to configure memcached as the EntityStore, since Rack::Cache will
# use this store for large objects. Dragonfly objects, for instance, will be
# cached in the EntityStore, whatever their size may be. Refinery::Images and
# Refinery::Resources both use Dragonfly.
#
# Example configuration of memcached and disk storage using the 'dalli' gem:
#
#     Rails.application.config.cache_store = :dalli_store
#     Rails.application.config.action_dispatch.rack_cache = {
#       :metastore    => Dalli::Client.new,
#       :entitystore  => URI.encode("file:#{Rails.root}/tmp/cache/rack/body"),
#       :allow_reload => false
#     }
#
module Refinery
  module Cache
    class << self
      ##
      # Configures Rails with a MemoryStore cache and injects the Rack::Cache
      # middleware if it's not already loaded.
      def attach!(app)
        app.config.cache_store = :memory_store, {:size => 32.megabytes}
        app.config.middleware.insert 0, 'Rack::Cache', {
          :verbose     => !::Rails.env.production?,
          :metastore   => default_metastore,
          :entitystore => default_entitystore
        } if insert_rack_cache_middleware?
      end

      ##
      # Avoid adding Rack::Cache twice since it's automatically enabled in
      # production by default as of Rails 3.1.
      def insert_rack_cache_middleware?
        !( rails_3_1_or_greater? && ::Rails.env.production? )
      end

      ##
      # True if the current version of rails is 3.1 or higher.
      def rails_3_1_or_greater?
        ::Gem.loaded_specs['rails'].version >= ::Gem::Version.new('3.1')
      end

      ##
      # A default MetaStore for Rack::Cache.
      #
      # This is likely to be accessed frequently, so a low-latency cache store
      # like memcached is advised in production.
      #
      # Why isn't this being stored in memory?
      # > from http://rtomayko.github.com/rack-cache/storage
      # > heap storage provides no mechanism for purging unused entries so
      # > memory use is guaranteed to exceed that available, given enough time
      # > and utilization.
      def default_metastore
        ::URI.encode("file:#{Rails.root}/tmp/cache/rack/meta")
      end

      ##
      # A default EntityStore for Rack::Cache.
      #
      # Disk Storage will grow until the disk is full unless old entries are
      # deleted periodically.
      #
      # By default Refinery::Resources may be up to 50MB and are cached in the
      # EntityStore.
      #
      # The Rack::Cache documentation suggests that disk storage is a good fit,
      # since the EntityStore can grow quite large, and it is not as sensitive
      # to latency as the MetaStore.
      def default_entitystore
        ::URI.encode("file:#{Rails.root}/tmp/cache/rack/body")
      end

      private :default_metastore, :default_entitystore,
              :insert_rack_cache_middleware?, :rails_3_1_or_greater?

    end
  end
end
