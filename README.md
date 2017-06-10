# Fluent::Plugin::Memcached, a plugin for [Fluentd](http://www.fluentd.org)

[![Build Status](https://travis-ci.org/innossh/fluent-plugin-memcached.svg?branch=master)](https://travis-ci.org/innossh/fluent-plugin-memcached)
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-memcached.svg)](https://badge.fury.io/rb/fluent-plugin-memcached)

Send your logs to Memcached.

## Requirements

| fluent-plugin-memcached | fluentd | ruby |
|-------------------------|---------|------|
| >= 0.1.0 | >= v0.14.0 | >= 2.1 |
|  < 0.1.0 | >= v0.12.0 | >= 1.9 |

## Installation

```console
$ gem install fluent-plugin-memcached
```

## Configuration

**NOTE: The version 0.2.0 includes breaking changes for configuration.** Please see [here](#for-previous-versions) if you use v0.1.1 or earlier.

In your Fluentd configuration, use `@type memcached`.

```
<match dummy>
  @type memcached
  host localhost # Optional, default:localhost
  port 11211     # Optional, default:11211

  key id            # Required, set a key name, the value of which is used as memcached key
  include_key false # Optional, default: false
  increment false   # Optional, default: false

  format csv             # Optional, default: csv
  fields field1,field2   # Required, set field names, the value of which is stored in memcached
  delimiter " "          # Optional, default: " "
  force_quotes false     # Optional, default: false
</match>
```

### Use cases

There are some results when the following input is coming.

input: `{"id" => "key1", "field1" => "value1", "field2" => "value2", "field_incr" => "1"}`

#### To store a data as CSV

```
<match dummy>
  @type memcached
  key id
  fields field1,field2
  delimiter ,
</match>
```

The result of stored a data is as below:

- key: `key1`
- value: `value1,value2`

#### To store a data as JSON

```
<match dummy>
  @type memcached
  key id
  fields field1,field2
  format json
</match>
```

The result of stored a data is as below:

- key: `key1`
- value: `{"field1":"value1","field2":"value2"}`

#### To store a data as single incremental value

```
<match dummy>
  @type memcached
  key id
  increment true
  format single_value
  message_key field_incr
</match>
```

The result of stored a data is as below:

- key: `key1`
- value: `1`

Then the following input is also coming,

input: `{"id" => "key1", "field1" => "value3", "field2" => "value4", "field_incr" => "2"}`

The result of stored a data will be as below:

- key: `key1`
- value: `3`

### Fluentd v0.14 style

When using v0.14 style configuration, you can choose three different types of buffer behavior:

#### Simple Buffered Output

```
<match dummy>
...
  <buffer>
    @type memory
  </buffer>
</match>
```

#### Tag Separated Buffered Output

```
<match dummy>
...
  <buffer tag>
    @type memory
  </buffer>
</match>
```

#### Time Sliced Buffered Output

```
<match dummy>
...
  <buffer tag, time>
    @type memory
    timekey 3600 # for 1 hour
  </buffer>
</match>
```

### For previous versions

In v0.1.1 or earlier, to store a data as JSON, like this:

```
<match dummy>
  @type memcached
  host localhost
  port 11211
  value_format json
  param_names param1,param2
</match>
```

## Contributing

Bug reports and pull requests are welcome.

## License

- Copyright (c) 2015 innossh
- [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
