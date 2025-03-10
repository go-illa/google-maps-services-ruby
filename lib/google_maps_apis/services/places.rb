require 'google_maps_apis/convert'

module GoogleMapsApis::Services

  # Performs requests to the Google Maps Geocoding API.
  module Places
    def places_autocomplete(input, components: nil, bounds: nil, types: nil, region: nil, language: nil)
      params = {}

      params[:input] = input
      params[:components] = GoogleMapsApis::Convert.components(components) if components
      params[:bounds] = GoogleMapsApis::Convert.bounds(bounds) if bounds
      params[:region] = region if region
      params[:language] = language if language
      params[:types] = types if types

      return get('/maps/api/place/autocomplete/json', params)[:predictions]
    end
  end
end
