require 'spec_helper'

describe GoogleMapsApis do
  it 'has a version number' do
    expect(GoogleMapsApis::VERSION).not_to be nil
  end

  it 'can detect os version' do
    expect(GoogleMapsApis::OS_VERSION).not_to be nil
  end
end
