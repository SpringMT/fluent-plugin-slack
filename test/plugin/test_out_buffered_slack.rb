require 'test_helper'
require 'time'

class SlackOutputTest < Test::Unit::TestCase

  def setup
    super
    Fluent::Test.setup
  end

  CONFIG = %[
    type slack
    web_hook_url hoge
    team    sowasowa
    channel test
    username testuser
    color    good
    icon_emoji :ghost:
    compress gz
    buffer_path ./test/tmp
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::SlackOutput).configure(conf)
  end

  def test_format
    d = create_driver
    time = Time.parse("2014-01-01 22:00:00 UTC").to_i
    d.tag = 'test'
    stub(d.instance.slack).ping(
      nil,
      channel:    'test',
      username:   'testuser',
      icon_emoji: ':ghost:',
      attachments: [{
        fallback: d.tag,
        color:    'good',
        fields:   [
          {
            title: d.tag,
            value: "[#{Time.at(time)}] sowawa\n"
          }]}])
    d.emit({message: 'sowawa'}, time)
    d.expect_format %[#{['test', time, {message: 'sowawa'}].to_msgpack}]
    d.run
  end

  def test_write
    d = create_driver
    time = Time.parse("2014-01-01 22:00:00 UTC").to_i
    d.tag  = 'test'
    stub(d.instance.slack).ping(
      nil,
      channel:    'test',
      username:   'testuser',
      icon_emoji: ':ghost:',
      attachments: [{
        fallback: d.tag,
        color:    'good',
        fields:   [
          {
            title: d.tag,
            value: "[#{Time.at(time)}] sowawa1\n" +
                     "[#{Time.at(time)}] sowawa2\n"
          }]}])
    d.emit({message: 'sowawa1'}, time)
    d.emit({message: 'sowawa2'}, time)
    d.run
  end
end
