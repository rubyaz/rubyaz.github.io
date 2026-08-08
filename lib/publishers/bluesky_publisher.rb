# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

class BlueskyPublisher < Publisher
  # TODO: Fill in these 1Password reference URIs
  OP_HANDLE = "op://Ruby::AZ/Ruby::AZ Bluesky/Handle"
  OP_APP_PASSWORD = "op://Private/Ruby::AZ Bluesky/App_Password"
  API = "https://bsky.social"

  def name = "Bluesky"
  def front_matter_key = "bluesky_post_url"

  def post(text, reply_to: nil)
    handle = fetch_op_secret(OP_HANDLE)
    return { error: "Failed to retrieve Bluesky handle from 1Password at #{OP_HANDLE}" } unless handle

    app_password = fetch_op_secret(OP_APP_PASSWORD)
    return { error: "Failed to retrieve Bluesky app password from 1Password at #{OP_APP_PASSWORD}" } unless app_password

    session = create_session(handle, app_password)
    return session if session[:error]

    facets = detect_facets(text)

    record = {
      "$type" => "app.bsky.feed.post",
      "text" => text,
      "createdAt" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ"),
    }
    record["facets"] = facets unless facets.empty?
    
    if reply_to
      cid = fetch_cid(session, reply_to)
      if cid
        record["reply"] = {
          "root" => { "uri" => reply_to, "cid" => cid },
          "parent" => { "uri" => reply_to, "cid" => cid }
        }
      end
    end

    body = {
      "repo" => session[:did],
      "collection" => "app.bsky.feed.post",
      "record" => record,
    }

    uri = URI("#{API}/xrpc/com.atproto.repo.createRecord")
    response = https_post_json(uri, body, auth: session[:access_jwt])

    unless response.is_a?(Net::HTTPSuccess)
      return { error: "Bluesky API error: #{response.code} #{response.body}" }
    end

    data = JSON.parse(response.body)
    rkey = data["uri"].split("/").last
    { id: data["uri"], url: "https://bsky.app/profile/#{handle}/post/#{rkey}" }
  end

  private

  def create_session(handle, app_password)
    uri = URI("#{API}/xrpc/com.atproto.server.createSession")
    body = { "identifier" => handle, "password" => app_password }
    response = https_post_json(uri, body)

    unless response.is_a?(Net::HTTPSuccess)
      return { error: "Bluesky auth failed: #{response.code} #{response.body}" }
    end

    data = JSON.parse(response.body)
    { did: data["did"], access_jwt: data["accessJwt"] }
  end

  def detect_facets(text)
    facets = []

    # URLs
    text.scan(/(https?:\/\/[^\s)]+)/) do
      match = Regexp.last_match
      byte_start = text[0...match.begin(0)].bytesize
      byte_end = byte_start + match[0].bytesize
      facets << {
        "index" => { "byteStart" => byte_start, "byteEnd" => byte_end },
        "features" => [{ "$type" => "app.bsky.richtext.facet#link", "uri" => match[0] }],
      }
    end

    # Hashtags
    text.scan(/(?<=\s|^)#(\w+)/) do
      match = Regexp.last_match
      tag_with_hash = "##{match[1]}"
      byte_start = text[0...match.begin(0)].bytesize
      byte_end = byte_start + tag_with_hash.bytesize
      facets << {
        "index" => { "byteStart" => byte_start, "byteEnd" => byte_end },
        "features" => [{ "$type" => "app.bsky.richtext.facet#tag", "tag" => match[1] }],
      }
    end

    facets
  end

  def https_post_json(uri, body, auth: nil)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{auth}" if auth
    request.body = JSON.generate(body)

    http.request(request)
  end

  def fetch_cid(session, uri)
    parts = uri.sub("at://", "").split("/")
    repo = parts[0]
    collection = parts[1]
    rkey = parts[2]
    
    get_uri = URI("#{API}/xrpc/com.atproto.repo.getRecord?repo=#{repo}&collection=#{collection}&rkey=#{rkey}")
    req = Net::HTTP::Get.new(get_uri)
    req["Authorization"] = "Bearer #{session[:access_jwt]}"
    
    http = Net::HTTP.new(get_uri.host, get_uri.port)
    http.use_ssl = true
    res = http.request(req)
    
    return nil unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)["cid"]
  end
end
