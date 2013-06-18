require 'minitest/autorun'
Bundler.require(:default, :test)

# Set up Mongoid
puts 'Initializing Mongoid ' + ENV['RACK_ENV']
Mongoid.load!(File.dirname(__FILE__) + '/../config/mongoid.yml')

puts "Initializing redis " + ENV["REDISTOGO_URL"]
redis_uri = URI.parse(ENV["REDISTOGO_URL"])

puts "Initializing Resque"
Resque.redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)
Resque.redis.namespace = "resque:lettersmashr"
Resque.inline = true # Make resque run synchronously during tests

# Creates test photo data, for use by tests
def create_test_photo_data
  @test_letter_photo_data = {
      char: 'a',
      tags: %w(tag1 tag2),
      flickr_id: 1,
      flickr_license: 1,
      flickr_last_update: DateTime.parse('2013-03-20 21:49:10 -0400').to_i,
      flickr_owner: 'owner1',
      flickr_url_sq: 'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
      flickr_url_t: 'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg',
      flickr_url_s: 'http://farm9.staticflickr.com/8227/8492182496_9994616090_m.jpg'
  }
  Letter.save(@test_letter_photo_data)

  @test_letter_photo_data2 = {
      char: 'a',
      tags: %w(tag2 tag3, tag4),
      flickr_id: 2,
      flickr_license: 1,
      flickr_last_update: DateTime.parse('2013-03-20 21:49:10 -0400').to_i,
      flickr_owner: 'owner1',
      flickr_url_sq: 'http://farm8.staticflickr.com/7131/7689864678_95fa61b20a_m.jpg',
      flickr_url_t: 'http://farm8.staticflickr.com/7131/7689864678_95fa61b20a_m.jpg',
      flickr_url_s: 'http://farm8.staticflickr.com/7131/7689864678_95fa61b20a_m.jpg'
  }
  Letter.save(@test_letter_photo_data2)

  @test_letter_photo_data3 = {
      char: 'b',
      tags: %w(tag2 tag4),
      flickr_id: 3,
      flickr_license: 1,
      flickr_last_update: DateTime.parse('2013-03-20 21:49:10 -0400').to_i,
      flickr_owner: 'owner1',
      flickr_url_sq: 'http://farm8.staticflickr.com/7055/8690917380_2ef7594d0f_m.jpg',
      flickr_url_t: 'http://farm8.staticflickr.com/7055/8690917380_2ef7594d0f_m.jpg',
      flickr_url_s: 'http://farm8.staticflickr.com/7055/8690917380_2ef7594d0f_m.jpg'
  }
  Letter.save(@test_letter_photo_data3)
end

def delete_test_photo_data
  Letter::Photo.delete_all
end
