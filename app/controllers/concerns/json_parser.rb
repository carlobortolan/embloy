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
      if target.class == String
        output_draft = insert(extract(input, origin), target, output)
        unless output_draft.nil?
          output = output_draft
        end
      elsif target.class == Array
        target.each do |target_key|
          output_draft = insert(extract(input, origin), target_key, output)
          unless output_draft.nil?
            output = output_draft
          end
        end
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
