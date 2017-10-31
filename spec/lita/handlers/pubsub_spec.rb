require "spec_helper"

describe Lita::Handlers::Pubsub, lita_handler: true do
  let(:robot) { Lita::Robot.new(registry) }
  subject { described_class.new(robot) }
  let(:room) { Lita::Room.new('foos') }

  it 'subscribes current channel to event' do
    send_message("lita subscribe foo", from: room)
    expect(replies.last).to eq("Subscribed foos to foo events")

    send_message("lita subscriptions", from: room)
    expect(replies.last).to eq('Subscriptions for foos: ["foo"]')
  end

  it 'unsubscribes current channel from event' do
    send_message("lita subscribe foo", from: room)
    expect(replies.last).to eq("Subscribed foos to foo events")

    send_message("lita subscriptions", from: room)
    expect(replies.last).to eq('Subscriptions for foos: ["foo"]')

    send_message("lita unsubscribe foo", from: room)
    expect(replies.last).to eq("Unsubscribed foos to foo events")

    send_message("lita subscriptions", from: room)
    expect(replies.last).to eq('Subscriptions for foos: []')
  end

  it 'does not fail when unsubscribing unsubscribed event' do
    send_message("lita unsubscribe bar", from: room)
    expect(replies.last).to eq(
      "There is no bar subscription in foos.\n" \
      'Current subscriptions: []'
    )
  end
end
