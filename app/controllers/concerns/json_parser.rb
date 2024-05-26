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
  def parse(config, data)
    label(data.dup)

    # puts(find_value_by_key(data, config))
  end

  private

  def label(data, label = -1)
    if data.class == Hash
      data.each do |key, value|
        if value.class == Hash
          label(value)
        elsif value.class == Array
          new = []
          value.each do |item|
            label += 1
            new << label(label!(item, label))
          end
          data[key] = new
        end
      end
    elsif data.class == Array
      new = []
      data.each do |item|
        label += 1
        new << label!(item, label)
      end
      data = new
    end

    return data
  end

  def label!(data, label)
    if data.class == Hash
      new_data = {}
      data.each do |key, value|
        new_key = "#{key}-#{label}"
        new_data[new_key] = data.delete(key)
        new_data[new_key] = label!(value, label) if value.class != String
      end
    elsif data.class == Array
      new_data = []
      data.each do |item|
        bin = label!(item, label) if item.class != String
        new_data << bin if bin
      end
    else
      new_data = data
    end
    new_data

  end

  def find_value_by_key(data, key)
    if data.class == Hash
      return data[key] if data.key?(key)
      data.each_value do |value|
        result = find_value_by_key(value, key)
        return result if result
      end
    elsif data.class == Array
      data.each do |item|
        result = find_value_by_key(item, key)
        return result if result
      end
    end
    nil
  end
end

module JsonParser_2
  extend ActiveSupport::Concern
  DELIMITER = '\\'

  def parse(input, config_file)
    config = YAML.load_file(config_file)
    config.delete('path').each { |key| input = input[key] }
    output = {}

    config.each do |origin, target|
      Array(target).each do |target|
        case target
        when String
          output_draft = insert(extract(input, origin), target, output)
          output = output_draft unless output_draft.nil?
        when Array
          output[target.first] = []
          bin = {}
          target.last.each do |target|
            # target: {"isRequired"=>"required"}
            target.each do |origin, target|
              extract(input, origin).each do |input|
                bin = insert(input, target, bin)
              end
            end
          end
        else
          puts "do nothing"
        end

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
      if key.split('*')[1] == 'A'
        index = key.split('*')[-2]
        break if index == 'A'
        input = input[index.to_i]
      end

      input = input[key.split('*')[-1]]
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
    request['authorization'] = "Basic #{Base64.strict_encode64(ENV.fetch(path[1], '') + ':')}"
    response = http.request(request)

    case response # TODO: Handle errors
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      nil
    end
  end

end
