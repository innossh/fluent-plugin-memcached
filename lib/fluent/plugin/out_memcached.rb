class Fluent::MemcachedOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('memcached', self)
  attr_reader :host, :port, :memcached

  def initialize
    super
    require 'dalli'
  end

  def configure(conf)
    super
    @host = conf.has_key?('host') ? conf['host'] : 'localhost'
    @port = conf.has_key?('port') ? conf['port'].to_i : 11211
  end

  def start
    super
    @memcached = Dalli::Client.new("#{host}:#{port}")
  end

  def shutdown
    @memcached.close
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def write(chunk)
    chunk.msgpack_each { |record|
      array = record[2].split(' ')
      key = array.first
      value = array.drop(1).join(' ')
      @memcached.set key, value
    }
  end

end
