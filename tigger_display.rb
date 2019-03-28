require_relative 'database'
require 'gosu'
require 'net/http'
require 'json'
require 'open3'

ACCESS_TOKEN = "7F4YYCOSJFFE5L7WLTRHTGKZQHAZNRWY"

# Sends a .wav file to Wit.ai to be processed. The results are 
# returned as a hashmap
def parse_wav(file)
  uri = URI.parse("https://api.wit.ai/speech?v=20170307")
  request = Net::HTTP::Post.new(uri)
  request.content_type = "audio/wav"
  request["Authorization"] = "Bearer #{ACCESS_TOKEN}"
  request.body = ""
  request.body << File.read("recordings/restroom_first_floor.wav")

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  raw_response = JSON.parse(response.body)["entities"]
  p JSON.parse(response.body)
  keys = raw_response.keys
  formatted_response = {}
  keys.each do |key|
    formatted_response.store(key, raw_response[key][0]["value"])  
  end

  #formatted_response.store("station_id", STATION_ID)
  return formatted_response
end

# Records 8 seconds of audio from the system's microphone.
# The stored file is named based on the time of recording.
def record_audio()
  file_name = Time.now.to_s
  stdout, status = Open3.capture2("arecord -D hw:1,0 -d 8 -f cd #{file_name}.wav -c 1")
  return file_name
end

class TiggerDisplay < Gosu::Window
	def initialize 
		super 640, 480
    self.caption = "Tigger Pi"

    @image_x, @image_y, @image_z = -960, -470, 0
    @timer = 0
    @font = Gosu::Font.new(48)
    @background_image = Gosu::Image.new("media/raspberry.png", tileable: true)
    @button_text = "I am Button"
    @response = ""
    @db = Database.new
	end

	def update
    #@timer += 1

    # If button pressed, enable mic and record question.
    if Gosu.button_down?(Gosu::MsLeft) && button_selected?
      #@background_image = Gosu::Image.new("media/confetti.jpg", tileable: true)
      @image_x, @image_y = 0, 0
      @button_text = "I was Button"
      @file_name = Thread.new {record_audio}  #TODO: Write timer in terms of 'record_audio' thread
      @mic_timer = Thread.new {sleep 8}
    end

    # Timer for prototype
    if @mic_timer.class == Thread && !@mic_timer.alive?
      @firebase_query = Thread.new { @db.getSomething(parse_wav("restroom_first_floor.wav")) }#record_audio))
      #@background_image = Gosu::Image.new("media/raspberry.png", tileable: true)  
      @image_x, @image_y, @image_z = -960, -470, 0
      @button_text = "I am Button"
      @mic_timer = nil
      @response = ""
    end

    if @firebase_query.class == Thread && !@firebase_query.alive?
      @response = @firebase_query.value
      @firebase_query = nil
      @response_timer = Thread.new {sleep 8}
    end

    if @response_timer.class == Thread && !@response_timer.alive?
      @response = ""
      @response_timer = nil
    end
	end

	def draw
    @background_image.draw(@image_x, @image_y, @image_z)

    Gosu.draw_rect(200, 150, 240, 130, Gosu::Color::RED)
    @font.draw_text(@button_text, 210, 185, 0)

    @font.draw_text(@response, 20, 300, 0)
  end

  # Is the cursor hovered over the button?
  def button_selected?
    self.mouse_x > 200 && self.mouse_x < 440 &&
      self.mouse_y > 150 and self.mouse_y < 280
  end
end

TiggerDisplay.new.show