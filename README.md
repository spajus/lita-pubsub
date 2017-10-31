# Lita PubSub

PubSub notification system for [Lita](https://www.lita.io/), ported from [Hubot
PubSub](https://github.com/spajus/hubot-pubsub).

[![Build Status](https://travis-ci.org/spajus/lita-pubsub.png?branch=master)](https://travis-ci.org/spajus/lita-pubsub?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/spajus/lita-pubsub/badge.svg?branch=master)](https://coveralls.io/github/spajus/lita-pubsub?branch=master)

## Possibilities

`lita-pubsub` allows you to build a simple, yet powerful monitoring / notification system using your corporate chat. Simply subscribe events in appropriate chat rooms and publish info about these events via HTTP calls or from other Lita handlers when they happen.

```
              Lita PubSub Event Flow

+--------------+ +--------------+ +---------------+
| Lita handler | | HTTP Request | | chat message  |<--+
+-------+------+ +-------+------+ +-------+-------+   |
        |                |                |           |
        |                v                |           |
        |        +-------------+          |           |
        +------->| lita-pubsub |<---------+           |
                 +-------+-----+                      |
                         |                            |
                         v                            |
                 +--------------+                     |
             +---+     Lita     +---+                 |
             |   +--------------+   |                 |
             |                      |                 |
             v                      v                 |
       +---------------+  +---------------+           |
       |  chatroom #1  |  |  chatroom #2  +-----------+
       +---------------+  +---------------+
```

## Installation

Add lita-pubsub to your Lita instance's Gemfile:

``` ruby
gem "lita-pubsub"
```

## Configuration

```ruby

# lita_config.rb

Lita.configure do |config|
  # optional password protection
  config.handlers.pubsub.http_password = 's3cr3t'
end
```

## Usage

```
lita subscribe <event>        # subscribes current room to event
lita unsubscribe <event>      # unsubscribes current room from event
lita unsubscribe all events   # unsubscribes current room from all events
lita subscriptions            # show subscriptions of current room
lita subscribers of <event>   # shows which rooms subscribe to event
lita all subscriptions        # show all existing subscriptions
lita publish <event> <data>   # triggers event
```

## HTTP Api

```
GET /publish?event=<event>&data=<text>[&password=<password>]
```

```
POST /publish
```

 * Content-Type: `application/json`
 * Body: `{ "password": "optional", "event": "event", "data": "text" }`

## Warning

HTTP password protection is trivial, and should not be used in public networks.
