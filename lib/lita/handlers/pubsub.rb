module Lita
  module Handlers
    class Pubsub < Handler
      config :http_password

      http.get('/publish', :http_get)
      http.post('/publish', :http_post)

      route(
        /^all subscriptions$/i,
        :all_subscriptions,
        command: true,
        help: { 'all subscriptions' => 'pubsub: shows all subscriptions' }
      )

      route(
        /^subscriptions$/i,
        :subscriptions,
        command: true,
        help: { 'subscriptions' => 'pubsub: shows current room subscriptions' }
      )

      route(
        /^subscribers (of )?([a-z0-9\-\.\:_]+)$/i,
        :subscribers,
        command: true,
        help: { 'subscriptions of EVENT' => 'pubsub: shows rooms subscribed to EVENT' }
      )

      route(
        /^subscribe ([a-z0-9\-\.\:_]+)$/i,
        :subscribe,
        command: true,
        help: { 'subscribe EVENT' => 'pubsub: subscribes room to event' }
      )

      route(
        /^unsubscribe ([a-z0-9\-\.\:_]+)$/i,
        :unsubscribe,
        command: true,
        help: { 'unsubscribe EVENT' => 'pubsub: subscribes current channel to event' }
      )

      route(
        /^unsubscribe all events$/i,
        :unsubscribe_all,
        command: true,
        help: { 'unsubscribe all events' => 'pubsub: unsubscribes current channel from all events' }
      )

      route(
        /^publish ([a-z0-9\-\.\:_]+) (.+)$/i,
        :publish,
        command: true,
        help: { 'publish EVENT DATA' => 'pubsub: publishes DATA to EVENT subscribers' }
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
        validate_http_password!(request.params['password'])
        robot.trigger(
          :pubsub,
          event: request.params['event'],
          data: request.params['data']
        )
        response.write('ok')
      end

      def http_post(request, response)
        data = JSON.parse(request.body.read)
        validate_http_password!(request.params['password'] || data['password'])
        robot.trigger(
          :pubsub,
          event: data['event'],
          data: data['data']
        )
        response.write('ok')
      end

      def all_subscriptions(response)
        events = redis.smembers('pubsub.events').sort
        subscriptions = events.map do |event|
          "#{event} -> #{redis.smembers("pubsub.events.#{event}").sort}"
        end
        response.reply("All subscriptions:\n#{subscriptions.join("\n")}")
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
        redis.sadd("pubsub.events", event)
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
          subscribers = redis.smembers("pubsub.events.#{event}")
          redis.srem("pubsub.events", event) if subscribers.empty?
          response.reply("Unsubscribed #{room.name} from #{event} events")
        else
          response.reply(
            "There is no #{event} subscription in #{room.name}.\n" \
            "Current subscriptions: #{subscriptions}"
          )
        end
      end

      def unsubscribe_all(response)
        room = response.room
        return response.reply('This command only works in a room') unless room
        subscriptions = redis.smembers("pubsub.rooms.#{room.id}").sort
        subscriptions.each do |event|
          redis.srem("pubsub.rooms.#{room.id}", event)
          redis.srem("pubsub.events.#{event}", room.id)
          subscribers = redis.smembers("pubsub.events.#{event}")
          redis.srem("pubsub.events", event) if subscribers.empty?
          response.reply("Unsubscribed #{room.name} from #{event} events")
        end
      end

      def publish(response)
        event, data = response.matches[0]
        robot.trigger(:pubsub, event: event, data: data)
      end

      private

      def validate_http_password!(password)
        return if config.http_password.nil? || config.http_password.empty?
        raise 'incorrect password!' if password != config.http_password
      end

      Lita.register_handler(self)
    end
  end
end
