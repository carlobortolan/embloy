# frozen_string_literal: true

Geocoder.configure(
  # set geocoding service (see below for supported options):
  lookup: :nominatim,

  # set default units to kilometers:
  units: :km
)
