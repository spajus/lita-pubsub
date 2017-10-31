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

## How It Works

```console
$ bundle exec lita start
Type "exit" or "quit" to end the session.
Lita > lita help pubsub
Lita: all subscriptions - pubsub: shows all subscriptions
Lita: subscriptions - pubsub: shows current room subscriptions
Lita: subscribers [of] EVENT - pubsub: shows rooms subscribed to EVENT
Lita: subscribe EVENT - pubsub: subscribes room to event. subscribe to
`unsubscribed.event` to debug missing events.
Lita: unsubscribe EVENT - pubsub: subscribes current channel to event
Lita: unsubscribe all events - pubsub: unsubscribes current channel from all
events
Lita: publish EVENT DATA - pubsub: publishes DATA to EVENT subscribers
Lita > lita subscriptions
Subscriptions for shell: []
Lita > lita subscribe jenkins
Subscribed shell to jenkins events
# You would normally use HTTP API at lita:8080/publish for same result
Lita > lita publish jenkins.build.fail Build #12141 failed!
*jenkins.build.fail*: Build #12141 failed!
Lita > lita publish nothing emptiness
Lita > lita subscribe unsubscribed.event
Subscribed shell to unsubscribed.event events
Lita > lita publish nothing emptiness
*unsubscribed.event*: nothing: emptiness
Lita > lita subscribers of jenkins
Subscribers of jenkins: ["shell"]
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

## Event Namespaces

Lita PubSub uses `.` as event namespace separator. I.e.: subscribing to `x.y`
also subscribes to `x.y.*` events.

## Handling unsubscribed events

Do `lita subscribe unsubscribed.event` in a room where you want all unrouted
events to get announced.

## Warning

HTTP password protection is trivial, and should not be used in public networks.
