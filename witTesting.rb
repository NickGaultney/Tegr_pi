require_relative 'database'
require 'net/http'
require 'json'

#client = Wit.new(access_token: access_token)

ACCESS_TOKEN = "7F4YYCOSJFFE5L7WLTRHTGKZQHAZNRWY"

	def parse_wav
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
	#p JSON.parse(response.body)
	keys = raw_response.keys
	formatted_response = {}
	keys.each do |key|
	  formatted_response.store(key, raw_response[key][0]["value"])  
	end

	#formatted_response.store("station_id", STATION_ID)
	return formatted_response
end

def database_response
	db = Database.new
	response = db.getSomething(parse_wav)
	return response
end