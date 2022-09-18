require 'google_maps_service/convert'

module GoogleMapsService::Apis

  # Performs requests to the Google Maps Geocoding API.
  module Places
    def places_autocomplete(input, components: nil, bounds: nil, types: nil, region: nil, language: nil)
      params = {}

      params[:input] = input
      params[:components] = GoogleMapsService::Convert.components(components) if components
      params[:bounds] = GoogleMapsService::Convert.bounds(bounds) if bounds
      params[:region] = region if region
      params[:language] = language if language
      params[:types] = types if types

      return get('/maps/api/place/autocomplete/json', params)[:predictions]
    end
  end
end
