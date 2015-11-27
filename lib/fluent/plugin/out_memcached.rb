class Fluent::MemcachedOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('memcached', self)

  config_param :host, :string, :default => 'localhost'
  config_param :port, :integer, :default => 11211

  config_param :value_format, :string, :default => 'raw'
  config_param :param_names, :string, :default => nil # nil doesn't allowed for json

  attr_accessor :memcached
  attr_accessor :formatter

  def initialize
    super
    require 'dalli'
  end

  def configure(conf)
    super
    if @value_format == 'json' and @param_names.nil?
      raise Fluent::ConfigError, "param_names MUST be specified in the case of json format"
    end
    @formatter = RecordValueFormatter.new(@value_format, @param_names)
  end

  def start
    super
    @memcached = Dalli::Client.new("#{@host}:#{@port}")
  end

  def shutdown
    @memcached.close
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def write(chunk)
    chunk.msgpack_each { |tag, time, record|
      @memcached.set @formatter.key(record), @formatter.value(record)
    }
  end

  class RecordValueFormatter
    attr_reader :value_format
    attr_reader :param_names

    def initialize(value_format, param_names)
      @value_format = value_format
      @param_names = param_names
    end

    def key(record)
      record.values.first
    end

    def value(record)
      case @value_format
        when 'json'
          values = record.values.drop(1)
          hash = {}
          @param_names.split(/\s*,\s*/).each_with_index { |param_name, i|
            hash[param_name] = (i > values.size - 1) ? nil : values[i]
          }
          hash.to_json
        else
          record.values.drop(1).join(' ')
      end
    end
  end

end
