# frozen_string_literal: true
require 'json'
require 'yaml'
require 'uri'
require 'net/http'
require 'base64'
require 'dotenv'
Dotenv.load(".env")

module JobParser
  extend ActiveSupport::Concern

  def parse(config, data)
    # TODO: handle fetch
    data = label(data.dup)
    bin = {}
    config.each do |target, origin|
      Array(target).each do |target|
        lol = origin_to_target(data, origin)
        if lol.class == Array
          lol_bin = []
          it_id = 0
          lol.each do |lol_item|
            only_arrays = lol_item.select { |k, v| v.class == Array }
            res = []
            0.upto(only_arrays.values[0].length - 1) do |i|
              res_b = {}
              lol_item.each do |k, v|
                orgs = origin[it_id][k].split('*')
                orgs.shift
                targs = k.split('*')
                targs.shift
                intersection = orgs & targs
                intersection.each do |int|
                  if int == '~'
                    next
                  end
                  k = k.split('*')

                  k[k.index(int)] = i
                  k = k.join
                  if v.class == Array
                    res_b[k] = v[i]
                  else
                    res_b[k] = v
                  end
                end
                res << res_b
                res.uniq!


              end
            end

            lol_bin = res
            it_id += 1
          end
          bin[target] = lol_bin

        else
          bin[target] = lol
        end

      end
    end
    bin

  end

  private
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
    request['authorization'] = "Basic #{Base64.strict_encode64(ENV.fetch(path[1], '') + ':')}"
    response = http.request(request)

    case response # TODO: Handle errors
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      nil
    end
  end

  def origin_to_target(data, origin)
    case origin
    when Array
      origin.map { |item| origin_to_target(data, item) }
    when Hash
      origin.transform_values { |item| origin_to_target(data, item) }
    when String
      process_string_origin(data, origin)
    else
      origin
    end
  end

  def process_string_origin(data, origin)
    value = origin.split('-')
    origin_key = value.shift
    if value.last&.start_with?('<') && value.last&.end_with?('>')
      process_task_string(data, origin_key, value.last)
    else
      process_indices(data, origin_key, value)
    end
  end

  def process_task_string(data, origin_key, task_string)
    task = task_string[1..-2].split('|')
    case task.first
    when 'fetch'
      # Implement fetch logic here if needed
      nil
    when 'enum'
      value = find_value_by_key(data, origin_key)
      pairs = task.last.split(',').map { |pair| pair.split(':') }
      pairs.to_h[value.to_s] || value
    end
  end

  def process_indices(data, origin_key, value)
    indices = value.select { |val| val.start_with?('*') && val.end_with?('*') }.map { |val| val[1..-2] }
    if indices.any?
      generate_combinations_and_fetch_values(data, origin_key, indices)
    else
      find_value_by_key(data, origin_key)
    end
  end

  def generate_combinations_and_fetch_values(data, origin_key, indices)
    values = []
    i = Array.new(indices.length, 0)

    loop do
      current_origin = origin_key.dup
      i.each { |index| current_origin += "-#{index}" }
      val = find_value_by_key(data, current_origin)
      values << val unless val.nil?

      break unless increment_indices(i, 100)
    end

    values
  end

  def increment_indices(i, max_value)
    n = i.length - 1
    while n >= 0
      if i[n] < max_value
        i[n] += 1
        return true
      else
        i[n] = 0
        n -= 1
      end
    end
    false
  end

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
    return "~" if key == '~'
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
