module Fluent
  class SlackOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('buffered_slack', self)
    config_param :web_hook_url, :string
    config_param :team,         :string
    config_param :channel,      :string
    config_param :username,     :string
    config_param :color,        :string
    config_param :icon_emoji,   :string

    attr_reader :slack

    def initialize
      super
      require 'uri'
      require 'net/http'
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def configure(conf)
      super
      @channel      = "##{conf['channel']}"
      @username     = conf['username']   || 'fluentd'
      @color        = conf['color']      || 'good'
      @icon_emoji   = conf['icon_emoji'] || ':question:'
      @team         = conf['team']
      @web_hook_url = conf['web_hook_url']
    end

    def write(chunk)
      messages = {}
      chunk.msgpack_each do |tag, time, record|
        messages[tag] = '' if messages[tag].nil?
        messages[tag] << "[#{Time.at(time).strftime("%H:%M:%S")}] #{record['message']}\n"
      end
      begin
        payload = {
          channel:    @channel,
          username:   @username,
          icon_emoji: @icon_emoji,
          attachments: [{
            fallback: messages.keys.join(','),
            color:    @color,
            fields:   messages.map{|k,v| {title: k, value: v} }
          }]}
        post_request(
          payload: payload.to_json
        )
      rescue => e
        $log.error("Slack Error: #{e.backtrace[0]} / #{e.message}")
      end
    end

    private

    def post_request(data)
      web_fook_url = URI.parse @web_hook_url
      req = Net::HTTP::Post.new web_fook_url.request_uri
      req.set_form_data(data)
      http = Net::HTTP.new web_fook_url.host, web_fook_url.port
      http.use_ssl = true
      res = http.request(req)
      if res.code != "200"
        raise BufferedSlackOutputError, "Slack.com - #{res.code} - #{res.body}"
      end
    end
  end
end
