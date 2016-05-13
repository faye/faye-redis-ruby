# Faye::Redis [![Build Status](https://travis-ci.org/faye/faye-redis-ruby.svg)](https://travis-ci.org/faye/faye-redis-ruby)

This plugin provides a Redis-based backend for the
[Faye](http://faye.jcoglan.com) messaging server. It allows a single Faye
service to be distributed across many front-end web servers by storing state and
routing messages through a [Redis](http://redis.io) database server.


## Usage

Pass in the engine and any settings you need when setting up your Faye server.

```rb
require 'faye'
require 'faye/redis'

bayeux = Faye::RackAdapter.new(
  :mount   => '/',
  :timeout => 25,
  :engine  => {
    :type  => Faye::Redis,
    :host  => 'redis.example.com',
    # more options
  }
)
```

The full list of settings is as follows.

* <b>`:uri`</b> - redis URL (example: `redis://:secretpassword@example.com:9000/4`)
* <b>`:host`</b> - hostname of your Redis instance
* <b>`:port`</b> - port number, default is `6379`
* <b>`:password`</b> - password, if `requirepass` is set
* <b>`:database`</b> - number of database to use, default is `0`
* <b>`:namespace`</b> - prefix applied to all keys, default is `''`
* <b>`:socket`</b> - path to Unix socket if `unixsocket` is set
* <b>`:master_name`</b> - name of the master, controlling sentinels, default is `nil`
* <b>`:sentinels`</b> - array of sentinels, default is `nil`

Sentinels could be specified as follows

```rb
sentinels = [
    'your_redis_host.com:26379',
    'your_redis_host.com:26380',
    'your_redis_host.com:26381'
  ]

sentinels = [
    {url:'blah://sentinel5.example.net:26381'},
    {url:'blah://sentinel5.example.net:26382'},
    {url:'blah://sentinel5.example.net:26383'}
  ]
```
When you specify sentinels, you should also specify master name.
Gem  em-hiredis-sentinel is used in order to get sentinel technology support
https://github.com/livehelpnow/em-hiredis-sentinel

## License

(The MIT License)

Copyright (c) 2011-2013 James Coglan

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the 'Software'), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

