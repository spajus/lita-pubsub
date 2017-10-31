module Lita
  module Handlers
    class Pubsub < Handler
      http.get('/pubsub/:event', :http_get)
      http.post('/pubsub/:event', :http_post)
      route(
        /^subscriptions$/i,
        :subscriptions,
        command: true,
        help: { 'subscriptions' => 'shows current room subscriptions' }
      )

      route(
        /^subscribers (of )?([a-z0-9\-\.\:_]+)$/i,
        :subscribers,
        command: true,
        help: { 'subscriptions of EVENT' => 'shows rooms subscribed to EVENT' }
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

      route(
        /^publish ([a-z0-9\-\.\:_]+) (.+)$/i,
        :publish,
        command: true,
        help: { 'publish EVENT DATA' => 'publishes DATA to EVENT subscribers' }
      )

      on(:pubsub) do |payload|
        event = payload[:event]
        rooms = redis.smembers("pubsub.events.#{event}")
        rooms.each do |room|
          target = Source.new(room: room)
          robot.send_message(target, payload[:data])
        end
      end

      def http_get(request, response)
        robot.trigger(
          :pubsub,
          event: request.env['router.params'][:event],
          data: request.params['payload']
        )
        response.write('ok')
      end

      def http_post(request, response)
        data = JSON.parse(request.body.read)
        robot.trigger(
          :pubsub,
          event: request.env['router.params'][:event],
          data: data['payload']
        )
        response.write('ok')
      end

      def subscriptions(response)
        room = response.room
        return response.reply('This command only works in a room') unless room
        subscriptions = redis.smembers("pubsub.rooms.#{room.id}").sort
        response.reply("Subscriptions for #{room.name}: #{subscriptions}")
      end

      def subscribers(response)
        event = response.matches[0][1]
        subscribers = redis.smembers("pubsub.events.#{event}").sort
        response.reply("Subscribers of #{event}: #{subscribers}")
      end

      def subscribe(response)
        event = response.matches[0][0]
        room = response.room
        return response.reply('This command only works in a room') unless room
        redis.sadd("pubsub.rooms.#{room.id}", event)
        redis.sadd("pubsub.events.#{event}", room.id)
        response.reply("Subscribed #{room.name} to #{event} events")
      end

      def unsubscribe(response)
        event = response.matches[0][0]
        room = response.room
        return response.reply('This command only works in a room') unless room
        subscriptions = redis.smembers("pubsub.rooms.#{room.id}").sort
        if subscriptions.include?(event)
          redis.srem("pubsub.rooms.#{room.id}", event)
          redis.srem("pubsub.events.#{event}", room.id)
          response.reply("Unsubscribed #{room.name} from #{event} events")
        else
          response.reply(
            "There is no #{event} subscription in #{room.name}.\n" \
            "Current subscriptions: #{subscriptions}"
          )
        end
      end

      def publish(response)
        event, data = response.matches[0]
        robot.trigger(:pubsub, event: event, data: data)
      end

      Lita.register_handler(self)
    end
  end
end
