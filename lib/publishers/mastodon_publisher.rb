# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

class MastodonPublisher < Publisher
  # TODO: Fill in these 1Password reference URIs
  OP_TOKEN = "op://Ruby::AZ/Ruby::AZ Mastodon/Access_Token"
  INSTANCE = "https://ruby.social"

  def name = "Mastodon"
  def front_matter_key = "mastodon_post_url"

  def post(text, reply_to: nil)
    token = fetch_op_secret(OP_TOKEN)
    return { error: "Failed to retrieve Mastodon token from 1Password at #{OP_TOKEN}" } unless token

    uri = URI("#{INSTANCE}/api/v1/statuses")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{token}"
    
    if reply_to && reply_to.include?("/")
      reply_to = reply_to.split("/").last
    end

    data = { "status" => text }
    data["in_reply_to_id"] = reply_to if reply_to
    request.set_form_data(data)

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      return { error: "Mastodon API error: #{response.code} #{response.body}" }
    end

    data = JSON.parse(response.body)
    { id: data["id"], url: data["url"] }
  end
end
