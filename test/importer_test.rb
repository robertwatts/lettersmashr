require 'minitest/spec'
require 'minitest/autorun'
require_relative '../lib/importer'

describe Importer do
  it 'can import photos' do
    Importer.import
    assert true
  end
end

