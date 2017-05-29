require 'dalli'
require 'fluent/plugin/output'

class Fluent::Plugin::MemcachedOutput < Fluent::Plugin::Output
  Fluent::Plugin.register_output('memcached', self)

  config_param :host, :string, :default => 'localhost'
  config_param :port, :integer, :default => 11211

  config_param :increment, :bool, :default => false
  config_param :value_separater, :string, :default => ' '

  config_param :value_format, :string, :default => 'raw'
  config_param :param_names, :string, :default => nil # nil doesn't allowed for json

  attr_accessor :memcached
  attr_accessor :formatter

  def initialize
    super
  end

  def configure(conf)
    super
    if @value_format == 'json' and @param_names.nil?
      raise Fluent::ConfigError, "param_names MUST be specified in the case of json format"
    end
    @formatter = RecordValueFormatter.new(@increment, @value_separater, @value_format, @param_names)
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
    [tag, time, record].to_msgpack
  end

  def formatted_to_msgpack_binary?
    true
  end

  def multi_workers_ready?
    true
  end

  def write(chunk)
    chunk.msgpack_each { |tag, time, record|
      key = @formatter.key(record)
      value = @formatter.value(record)
      if @increment
        if @memcached.get(key) == nil
          # initialize increment value
          @memcached.incr(key, 1, nil, 0)
        end
        @memcached.incr(key, amt=value)

      else
        @memcached.set(key, value)
      end
    }
  end

  class RecordValueFormatter
    attr_reader :increment
    attr_reader :value_separater
    attr_reader :value_format
    attr_reader :param_names

    def initialize(increment, value_separater, value_format, param_names)
      @increment = increment
      @value_separater = value_separater
      @value_format = value_format
      @param_names = param_names
    end

    def key(record)
      record.values.first
    end

    def value(record)
      values = record.values.drop(1)
      case @value_format
        when 'json'
          hash = {}
          @param_names.split(/\s*,\s*/).each_with_index { |param_name, i|
            hash[param_name] = (i > values.size - 1) ? nil : values[i]
          }
          hash.to_json
        else
          return values.first.to_i if @increment

          values.join(@value_separater)
      end
    end
  end

end
