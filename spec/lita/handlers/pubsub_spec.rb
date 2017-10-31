require "spec_helper"

describe Lita::Handlers::Pubsub, lita_handler: true do
  let(:robot) { Lita::Robot.new(registry) }
  subject { described_class.new(robot) }
  let(:room) { Lita::Room.new('foos') }
  let(:room2) { Lita::Room.new('bars') }

  it 'subscribes current channel to event' do
    send_message('lita subscribe foo', from: room)
    send_message('lita subscriptions', from: room)
    expect(replies.last).to eq('Subscriptions for foos: ["foo"]')
  end

  it 'unsubscribes current channel from event' do
    send_message('lita subscribe foo', from: room)
    send_message('lita subscriptions', from: room)
    expect(replies.last).to eq('Subscriptions for foos: ["foo"]')

    send_message('lita unsubscribe foo', from: room)
    expect(replies.last).to eq("Unsubscribed foos from foo events")

    send_message('lita subscriptions', from: room)
    expect(replies.last).to eq('Subscriptions for foos: []')
  end

  it 'shows room subscriptions' do
    send_message('lita subscribe foo', from: room)
    send_message('lita subscriptions', from: room)
    expect(replies.last).to eq('Subscriptions for foos: ["foo"]')
  end

  it 'shows all subscriptions' do
    send_message('lita subscribe foo', from: room)
    send_message('lita subscribe bar', from: room)
    send_message('lita subscribe bar', from: room2)
    send_message('lita all subscriptions')
    expect(replies.last).to eq("All subscriptions:\nbar -> [\"bars\", \"foos\"]\nfoo -> [\"foos\"]")
  end

  it 'shows subscribers of event' do
    send_message("lita subscribe foo", from: room)
    send_message("lita subscribe foo", from: room2)

    send_message("lita subscribers foo")
    expect(replies.last).to eq('Subscribers of foo: ["bars", "foos"]')

    send_message("lita subscribers of foo")
    expect(replies.last).to eq('Subscribers of foo: ["bars", "foos"]')
  end

  it 'publishes data to event subscribers' do
    send_message("lita subscribe foo", from: room)
    send_message("lita subscribe foo", from: room2)
    send_message("lita publish foo bar de baz")
    expect(replies[-1]).to eq('bar de baz')
    expect(replies[-2]).to eq('bar de baz')
  end

  it 'does not fail when unsubscribing unsubscribed event' do
    send_message("lita unsubscribe bar", from: room)
    expect(replies.last).to eq(
      "There is no bar subscription in foos.\n" \
      'Current subscriptions: []'
    )
  end

  context 'http request' do
    before { Lita.config.handlers.pubsub.http_password = 'secret' }

    it 'receives events via http get' do
      send_message("lita subscribe foo", from: room)
      http.get('/pubsub/foo?payload=bar%20baz&password=secret')
      expect(replies.last).to eq('bar baz')
    end

    it 'receives events via http post' do
      send_message("lita subscribe foo", from: room)
      http.post(
        '/pubsub/foo',
        '{"payload":"bar baz", "password":"secret"}',
        'Content-Type' => 'application/json'
      )
      expect(replies.last).to eq('bar baz')
    end

    it 'receives events via http get when password is not set' do
      send_message("lita subscribe foo", from: room)
      Lita.config.handlers.pubsub.http_password = nil
      http.get('/pubsub/foo?payload=bar%20baz')
      expect(replies.last).to eq('bar baz')
    end

    it 'rejects http request without any password' do
      expect {
        http.get('/pubsub/foo?payload=bar%20baz')
      }.to raise_error('incorrect password!')
    end

    it 'rejects bad password via http get' do
      expect {
        http.get('/pubsub/foo?payload=bar%20baz&password=haxor')
      }.to raise_error('incorrect password!')
    end

    it 'rejects bad password via http post' do
      expect {
        http.post(
          '/pubsub/foo',
          '{"payload":"bar baz", "password":"lol"}',
          'Content-Type' => 'application/json'
        )
      }.to raise_error('incorrect password!')
    end

    it 'ignores invalid http event' do
      send_message("lita subscribe foo", from: room)
      http.post(
        URI.escape('/pubsub/^leet*haX0r'),
        '{"payload":"bar baz"}',
        'Content-Type' => 'application/json'
      )
      expect(replies.last).to eq('Subscribed foos to foo events')
    end
  end
end
