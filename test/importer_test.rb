require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/../lib/importer'

class ImporterTest < MiniTest::Unit::TestCase

  def setup
    @importer = Importer.new
  end

  def test_last_import_record
    assert @importer.last_import_record, 'Cannot determine last record'
    puts 'Found last record' + @importer.last_import_record.to_s
  end



end
