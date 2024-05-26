# frozen_string_literal: true
require 'json'
require 'yaml'
require 'uri'
require 'net/http'
require 'base64'
require 'dotenv'
Dotenv.load(".env")
module JsonParser
  extend ActiveSupport::Concern
  DELIMITER = '\\'

  def parse(input, config_file)
    config = YAML.load_file(config_file)
    config.delete('path').each { |key| input = input[key] }
    output = {}

    config.each do |origin, target|
      Array(target).each do |target|
        output_draft = insert(extract(input, origin), target, output)
        output = output_draft unless output_draft.nil?
      end
    end

    output
  end

  private

  def insert (value, path, output)
    path = path.split(DELIMITER)

    if path.first == 'fetch'
      path.shift
      value = fetch(path, value)
      return nil if value.nil?
      path.shift
      path.shift
    end

    path.each do |key|
      if key == path.last
        output[key] = value
      elsif !output[key].nil?
        output = output[key]
      end

    end
    return output

  end

  def extract (input, path)
    path.split(DELIMITER).each do |key|
      input = input[key]
    end
    input
  end

  def fetch (path, input = nil)

    url = URI(path.first)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    if path[2] == 'post'
      request = Net::HTTP::Post.new(url)
    else
      request = Net::HTTP::Get.new(url)
    end

    if path[3] == 'json'
      request["accept"] = 'application/json'
      request["content-type"] = 'application/json'
    end

    request.body = "{\"#{path[-2]}\":\"#{input["primaryLocationId"]}\"}"
    p
    request['authorization'] = "Basic #{Base64.strict_encode64(ENV.fetch(path[1], '')+':')}"
    response = http.request(request)

    case response # TODO: Handle errors
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      nil
    end
  end

end
