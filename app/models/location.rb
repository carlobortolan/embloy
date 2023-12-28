# frozen_string_literal: true

# The Location class represents a location in the application.
class Location < ApplicationRecord
  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :code_country, presence: true
  validates :administrative_area, presence: true
  validates :sub_administrative_area,
            presence: true
  validates :locality, presence: true
  validates :address, presence: true
  validates :postal_code, presence: true
  validates :premise, presence: true
end
