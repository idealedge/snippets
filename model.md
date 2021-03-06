# Namespaces

## Redis

### `rds:groups`

* `key`: zero-padded integer key
* `value`: JSON hash with command pretty name and list of related commands for
runtime filtering

e.g:

    $ get("rds:groups", "0003") | jshon
    {
     "name": "Hashes",
     "cmds": [
      "hdel",
      "hget",
      "hgetall",
      "hset",
      "hlen"
     ]
    }

### `rds:cmds`

* `key`: command identifier (= filename under `redis-doc/commands/*.md` files)
* `value`: JSON hash with command pretty name, summary and list of CLI commands
used to initialize the interpretor

e.g:

    $ get("rds:cmds", "get") | jshon
    {
     "name": "GET",
     "args": "key",
     "summary": "Get the value of a key"
     "cli": ["GET nonexisting","SET mykey "Hello","GET mykey"]
    }

### `rds:docs`

* `key`: command identifier (= filename under `redis-doc/commands/*.md` files)
* `value`: HTML fragment

e.g:

    $ get("rds:docs", "get") | jshon
    <header><h1>GET</h1><h2>key</h2></header><h3>Available since 1.0.0</h3>...
