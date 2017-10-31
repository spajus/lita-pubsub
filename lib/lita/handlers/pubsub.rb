module Lita
  module Handlers
    class Pubsub < Handler
      route(
        /^subscriptions/i,
        :subscriptions,
        command: true,
        help: { 'subscriptions' => 'shows current room subscriptions' }
      )

      route(
        /^subscribe ([a-z0-9\-\.\:_]+)$/i,
        :subscribe,
        command: true,
        help: { 'subscribe EVENT' => 'subscribes room to event' }
      )

      route(
        /^unsubscribe ([a-z0-9\-\.\:_]+)$/i,
        :unsubscribe,
        command: true,
        help: { 'unsubscribe EVENT' => 'subscribes current channel to event' }
      )

      def subscriptions(response)
        room = response.room
        return response.reply('This command only works in a room') unless room
        subscriptions = redis.smembers("pubsub.subscriptions.#{room.id}")
        response.reply("Subscriptions for #{room.name}: #{subscriptions}")
      end

      def subscribe(response)
        event = response.matches[0][0]
        room = response.room
        return response.reply('This command only works in a room') unless room
        redis.sadd("pubsub.subscriptions.#{room.id}", event)
        response.reply("Subscribed #{room.name} to #{event} events")
      end

      def unsubscribe(response)
        event = response.matches[0][0]
        room = response.room
        return response.reply('This command only works in a room') unless room
        subscriptions = redis.smembers("pubsub.subscriptions.#{room.id}")
        if subscriptions.include?(event)
          redis.srem("pubsub.subscriptions.#{room.id}", event)
          response.reply("Unsubscribed #{room.name} to #{event} events")
        else
          response.reply(
            "There is no #{event} subscription in #{room.name}.\n" \
            "Current subscriptions: #{subscriptions}"
          )
        end
      end

      Lita.register_handler(self)
    end
  end
end
