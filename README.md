# Fluent::Plugin::Memcached, a plugin for [Fluentd](http://www.fluentd.org)

[![Build Status](https://travis-ci.org/innossh/fluent-plugin-memcached.svg?branch=master)](https://travis-ci.org/innossh/fluent-plugin-memcached)
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-memcached.svg)](https://badge.fury.io/rb/fluent-plugin-memcached)

Send your logs to Memcached.

## Requirements

| fluent-plugin-memcached | fluentd | ruby |
|------------------------|---------|------|
| >= 0.1.0 | >= v0.14.0 | >= 2.1 |
|  < 0.1.0 | >= v0.12.0 | >= 1.9 |

## Installation

```sh
$ gem install fluent-plugin-memcached
```

## Usage

In your Fluentd configuration, use `type memcached`.  
Default values would look like this:

```
<match dummy>
  type memcached
  host localhost
  port 11211
  increment false
  # value_separater " "
</match>
```

To store values as json, like this:

```
<match dummy>
  type memcached
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
