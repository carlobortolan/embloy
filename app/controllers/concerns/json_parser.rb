# frozen_string_literal: true
require 'json'
require 'yaml'
module JsonParser
  extend ActiveSupport::Concern

  def parse(input, config_file)
    config = YAML.load_file(config_file)
    prefixes = config.delete('path')
    prefixes.each { |key| input = input[key] }
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
    path = path.split('.')

    if path.first == 'fetch'
      return nil
      # TODO: Implement fetch
      # path.shift
      # ...
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
    path.split('.').each do |key|
      input = input[key]
    end
    input
  end

end
