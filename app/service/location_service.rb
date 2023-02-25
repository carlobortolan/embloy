# frozen_string_literal: true

class LocationService
  def initialize
    @location_repository = LocationRepository.new
  end

  def add_location(location)
    @location_repository.add_location(location)
  end

  def remove_location(id)
    @location_repository.remove_location(id)
  end

  def find_location(id)
    @location_repository.find_location(id)
  end

  def find_all
    @location_repository.find_all
  end
end
