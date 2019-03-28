require 'firebase'

class Database
  def initialize
    private_key = File.open('tegr-pi-demo-firebase-adminsdk-luyn5-378c3b9134.json').read
    base_uri = 'https://tegr-pi-demo.firebaseio.com/'
    @firebase = Firebase::Client.new(base_uri, private_key)
  end

  def getSomething(witInput)
    path = witInput["intent"] + "/" + witInput["floor_type"] + "/location"
    response = @firebase.get(path)
    return response.body  
  end
end
=begin
db = Database.new
loop do
  print "Find bathroom on what floor: "
  floor = gets.chomp
  break if floor == "Q"
  puts(db.getSomething({"intent" =>"bathrooms", "floor_type" => floor, "station_id" => 1}))

end
=end