require 'test/unit'
require 'fluent/test'
require 'fluent/plugin/out_memcached'

class MemcachedOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    host 127.0.0.1
    port 11211
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::MemcachedOutput, tag).configure(conf)
  end

  def test_configure
    d = create_driver('')

    assert_equal 'localhost', d.instance.host
    assert_equal 11211, d.instance.port

    d = create_driver

    assert_equal '127.0.0.1', d.instance.host
    assert_equal 11211, d.instance.port
  end

  def test_format
    d = create_driver
    time = Time.parse('2011-01-02 13:14:15 UTC').to_i
    d.emit('a 1', time)
    d.expect_format(['test', time, 'a 1'].to_msgpack)
    d.run
  end

  def test_write
    d = create_driver
    time = Time.parse('2011-01-02 13:14:15 UTC').to_i
    d.emit('a 1', time)
    d.run

    assert_equal '1', d.instance.memcached.get('a')
  end
end
