# Fluent::Plugin::Memcached, a plugin for [Fluentd](http://www.fluentd.org)

[![Build Status](https://travis-ci.org/innossh/fluent-plugin-memcached.svg?branch=master)](https://travis-ci.org/innossh/fluent-plugin-memcached)

Send your logs to Memcached.

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
</match>
```

## Contributing

Bug reports and pull requests are welcome.

## License

- Copyright (c) 2015 innossh
- [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
