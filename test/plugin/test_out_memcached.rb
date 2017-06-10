require 'fluent/test'
require 'fluent/test/helpers'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_memcached'

class MemcachedOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  def setup
    Fluent::Test.setup

    @d = create_driver
    # Invalidate all existing cache items before testing
    Dalli::Client.new("#{@d.instance.host}:#{@d.instance.port}").flush_all
    @time = event_time('2011-01-02 13:14:15 UTC')
  end

  CONFIG = %[
    key id
    fields field1,field2
  ]

  CONFIG_JSON = %[
    key id
    include_key true
    format json
    include_tag_key true
  ]

  CONFIG_INCREMENT = %[
    key id
    format single_value
    message_key field_incr
    increment true
  ]

  CONFIG_MYSQL = %[
    include_time_key true
    time_format %s
    key time
    fields metrics_name,metrics_value
    delimiter |
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::MemcachedOutput).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      create_driver('')
    }

    assert_equal 'localhost', @d.instance.host
    assert_equal 11211, @d.instance.port
    assert_equal false, @d.instance.increment
    assert_equal ' ', @d.instance.formatter.delimiter
    assert_equal 'id', @d.instance.key
    assert_equal ['field1', 'field2'], @d.instance.formatter.fields

    d = create_driver(CONFIG_JSON)
    assert_equal 'json', d.instance.formatter_configs.first[:@type]

    d = create_driver(CONFIG_INCREMENT)
    assert_equal true, d.instance.increment
    assert_equal 'single_value', d.instance.formatter_configs.first[:@type]
    assert_equal 'field_incr', d.instance.formatter.message_key

    d = create_driver(CONFIG_MYSQL)
    assert_equal 'time', d.instance.key
    assert_equal true, d.instance.include_time_key
    assert_equal '%s', d.instance.inject_config.time_format
    assert_equal ['metrics_name', 'metrics_value'], d.instance.formatter.fields
    assert_equal '|', d.instance.formatter.delimiter
  end

  def test_format
    record = {'id' => 'key', 'field1' => 'value1', 'field2' => 'value2'}
    @d.run(default_tag: 'test') do
      @d.feed(@time, record)
    end
    assert_equal [[@time.to_i, 'key', 'value1 value2'].to_msgpack], @d.formatted
  end

  def test_write
    @d = create_driver
    record1 = {'id' => 'a', 'field1' => '1'}
    record2 = {'id' => 'b', 'field1' => '2', 'field2' => '3'}
    @d.run(default_tag: 'test') do
      @d.feed(@time, record1)
      @d.feed(@time, record2)
    end

    assert_equal '1 ', @d.instance.memcached.get('a')
    assert_equal '2 3', @d.instance.memcached.get('b')
  end

  def test_write_json
    d = create_driver(CONFIG_JSON)
    record1 = {'id' => 'a', 'field1' => '4'}
    record2 = {'id' => 'b', 'field1' => '5', 'field2' => '6'}
    record1_value_json = {'id' => 'a', 'field1' => '4', 'tag' => 'test'}.to_json
    record2_value_json = {'id' => 'b', 'field1' => '5', 'field2' => '6', 'tag' => 'test'}.to_json
    d.run(default_tag: 'test') do
      d.feed(@time, record1)
      d.feed(@time, record2)
    end

    assert_equal record1_value_json, d.instance.memcached.get('a')
    assert_equal record2_value_json, d.instance.memcached.get('b')
  end

  def test_write_increment
    d = create_driver(CONFIG_INCREMENT)
    record1 = {'id' => 'count1', 'field_incr' => 1}
    record2 = {'id' => 'count2', 'field_incr' => 2}
    record3 = {'id' => 'count1', 'field_incr' => 3}
    record4 = {'id' => 'count2', 'field_incr' => 4}
    d.run(default_tag: 'test') do
      d.feed(@time, record1)
      d.feed(@time, record2)
      d.feed(@time, record3)
      d.feed(@time, record4)
    end

    assert_equal (1 + 3), d.instance.memcached.get('count1').to_i
    assert_equal (2 + 4), d.instance.memcached.get('count2').to_i
  end

  def test_write_to_mysql
    d = create_driver(CONFIG_MYSQL)
    record = {'metrics_name' => 'count', 'metrics_value' => '100'}
    d.run(default_tag: 'test') do
      d.feed(@time, record)
    end

    assert_equal 'count|100', d.instance.memcached.get(@time.to_i)
  end

end
