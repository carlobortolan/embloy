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
  class JobParserResult < Hash
    def initialize(data = {})
      super()
      data.each { |key, value| self[key] = value }
    end

    def to_active_record(data = self)
      data.keys.each do |key|
        value = data[key]

        data[key] = [] if key.to_s == 'application_options' #TODO: REMOVE AND HANDLE APPLICATION OPTIONS SEPERATELY

        if value.is_a?(Array)
          value.each { |item| to_active_record(item) if item.is_a?(Hash) }
        elsif value.is_a?(Hash)
          to_active_record(value)
        else
          data[key] = nil if value == '~'
        end

        if key.to_s.include?('-')
          new_key = key.split('-').first
          data[new_key] = data.delete(key)
        end
      end
      data
    end

  end



  def self.parse(config, data)
    # TODO: redo application options
    data = label(data.dup)
    bin = {}
    config.each do |target, origin|
      Array(target).each do |target|
        lol = origin_to_target(data, origin)
        if lol.class == Array
          lol_bin = []
          path = []

          lol.each_with_index do |lol_item, it_id|
            only_arrays = lol_item.select { |_, v| v.is_a?(Array) }
            result_set = []

            only_arrays.values[0].each_index do |i|
              transformed_item = {}

              lol_item.each do |key, value|
                orgs = origin[it_id][key].split('*').drop(1)
                targs = key.split('*').drop(1)
                intersection = orgs & targs

                intersection.reject { |int| int == '~' }.each do |int|
                  new_key = key.split('*').tap { |k| k[k.index(int)] = i }.join
                  transformed_item[new_key] = value.is_a?(Array) ? value[i] : value
                end
              end

              result_set << transformed_item unless result_set.include?(transformed_item)
            end

            origin[it_id].each do |_, value|
              path.concat(value.split('*').drop(1).map { |x| x == "~" })
            end

            lol_bin << result_set
          end

          bin[target] = lol_bin
          path.each_with_index { |p, i| bin[target] = bin[target].flatten if p }
        else
          bin[target] = lol
        end
      end
    end
    JobParserResult.new(bin)

  end

  private

  def self.fetch (path, origin_key, input = nil)
    url = URI(path.first)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    if path[1] == 'POST'
      request = Net::HTTP::Post.new(url)
    else
      request = Net::HTTP::Get.new(url)
    end

    if path[2] == 'JSON'
      request["accept"] = 'application/json'
      request["content-type"] = 'application/json'
    end
    request.body = "{\"#{path[-2]}\":\"#{find_value_by_key(input, origin_key)}\"}"
    request['authorization'] = "Basic #{Base64.strict_encode64("94befa3e484fbfa12ae6929f81c9b289ec37e3a6072473c6dbdf2992eb6c5ccf" + ':')}"
    response = http.request(request)
    case response # TODO: Handle errors
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      nil
    end
  end

  def self.origin_to_target(data, origin)
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

  def self.process_string_origin(data, origin)
    value = origin.split('-')
    origin_key = value.shift
    if value.last&.start_with?('<') && value.last&.end_with?('>')
      process_task_string(data, origin_key, value.last)
    else
      process_indices(data, origin_key, value)
    end
  end

  def self.process_task_string(data, origin_key, task_string)
    task = task_string[1..-2].split('|')
    case task.first
    when 'fetch'
      task.shift
      path = task[0].split(',')
      results = fetch(path,origin_key, data)
      path[-1].split('.').each { |key| results = results[key] }
      results
    when 'enum'
      value = find_value_by_key(data, origin_key)
      pairs = task.last.split(',').map { |pair| pair.split(':') }
      pairs.to_h[value.to_s] || value
    end
  end

  def self.process_indices(data, origin_key, value)
    indices = value.select { |val| val.start_with?('*') && val.end_with?('*') }.map { |val| val[1..-2] }
    if indices.any?
      generate_combinations_and_fetch_values(data, origin_key, indices)
    else
      find_value_by_key(data, origin_key)
    end
  end

  def self.generate_combinations_and_fetch_values(data, origin_key, indices)
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

  def self.increment_indices(i, max_value)
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

  def self.label(data, label = -1)
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

  def self.label!(data, label)
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

  def self.find_value_by_key(data, key)
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
