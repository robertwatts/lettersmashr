

MockPhoto = Struct.new(:id, :license, :lastupdate, :owner, :url_sq, :url_t, :url_s, :url_q, :tags)

# Uses duck-typing to behave like FlickrPhotoCollector to provide Flickr like data
class TestPhotoCollector
  attr_reader :photo_count

  def initialize
    puts 'Initializing Test Photo Collector'
    @photo_count = 3

    @test_letter_data = MockPhoto.new(
        1, 1, DateTime.parse('2013-03-20 21:49:10 -0400').to_i, 'owner1', 
        'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
        'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
        'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
        'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
        'tag1 tag2 a'
      )
      
    @test_letter_data2 = MockPhoto.new(
        2, 1, DateTime.parse('2013-03-20 21:49:10 -0400').to_i, 'owner1', 
        'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
        'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
        'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
        'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
        'tag2 tag3 tag4 a'
      )

    @test_letter_data3 = MockPhoto.new(
        3, 1, DateTime.parse('2013-03-20 21:49:10 -0400').to_i, 'owner1', 
        'http://farm8.staticflickr.com/7055/8690917380_2ef7594d0f_m.jpg',
        'http://farm8.staticflickr.com/7055/8690917380_2ef7594d0f_m.jpg',
        'http://farm8.staticflickr.com/7055/8690917380_2ef7594d0f_m.jpg',
        'http://farm8.staticflickr.com/7055/8690917380_2ef7594d0f_m.jpg',
        'tag2 tag4 tag5 b'
      )
  end

  def get_photos
    [@test_letter_data, @test_letter_data2, @test_letter_data3]
  end

end

