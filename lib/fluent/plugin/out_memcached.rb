require 'dalli'
require 'fluent/plugin/output'

module Fluent::Plugin
  class MemcachedOutput < Output
    Fluent::Plugin.register_output('memcached', self)

    include Fluent::SetTimeKeyMixin
    include Fluent::SetTagKeyMixin

    helpers :inject, :formatter, :compat_parameters

    DEFAULT_BUFFER_TYPE = 'memory'
    DEFAULT_FORMAT_TYPE = 'csv'

    config_param :host, :string, :default => 'localhost'
    config_param :port, :integer, :default => 11211
    config_param :key, :string
    config_param :include_key, :bool, :default => false
    config_param :increment, :bool, :default => false

    config_section :buffer do
      config_set_default :@type, DEFAULT_BUFFER_TYPE
    end

    config_section :format do
      config_set_default :@type, DEFAULT_FORMAT_TYPE
      config_set_default :delimiter, ' '
      config_set_default :force_quotes, false
    end

    attr_accessor :memcached
    attr_accessor :formatter

    def configure(conf)
      compat_parameters_convert(conf, :buffer, :inject, :formatter)
      super

      @formatter = formatter_create
    end

    def start
      super

      @memcached = Dalli::Client.new("#{@host}:#{@port}")
    end

    def shutdown
      @memcached.close

      super
    end

    def format(tag, time, record)
      record = inject_values_to_record(tag, time, record)

      key = @include_key ? record[@key] : record.delete(@key)
      [time, key, @formatter.format(tag, time, record).chomp].to_msgpack
    end

    def formatted_to_msgpack_binary?
      true
    end

    def multi_workers_ready?
      true
    end

    def write(chunk)
      chunk.msgpack_each do |time, key, value|
        unless @increment
          @memcached.set(key, value)
          next
        end

        @memcached.incr(key, value.to_i, nil, value.to_i)
      end
    end

  end
end
