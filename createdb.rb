# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :events do
  primary_key :id
  String :title
  String :description, text: true
  String :date
  String :location
  String :price
  String :long
  String :lat
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :event_id
  foreign_key :user_id
  Boolean :going
  String :billing_name
  String :billing_address
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
events_table = DB.from(:events)

events_table.insert(title: "Coachella", 
                    description: "The Coachella Valley Music and Arts Festival is an annual music and arts festival held at the Empire Polo Club.",
                    date: "April 10-12",
                    location: "Indio, CA", 
                    price: "$1,000",
                    long: "33.678368", 
                    lat: "-116.239371")

events_table.insert(title: "EDC", 
                    description: "EDC is the largest electronic dance music festival in North America.",
                    date: "May 15-17",
                    location: "Las Vegas, NV",
                    price: "$925", 
                    long: "36.2721997", 
                    lat: "-115.0122888")

events_table.insert(title: "Outside Lands", 
                    description: "The Outside Lands Music and Arts Festival is a music festival featuring a diverse selection of artists.",
                    date: "August 7-9",
                    location: "San Francisco, CA", 
                    price: "$900",
                    long: "37.7671962", 
                    lat: "-122.4927452")

events_table.insert(title: "Stagecoach", 
                    description: "The Stagecoach Festival is an outdoor country music festival held at the Empire Polo Club.",
                    date: "April 24-26",
                    location: "Indio, CA",
                    price: "$975",
                    long: "33.678368", 
                    lat: "-116.239371")

events_table.insert(title: "Ultra", 
                    description: "Ultra Music Festival is an annual outdoor electronic music festival featuring some of the best DJ's in the world.",
                    date: "March 20-21",
                    location: "Miami, FL", 
                    price: "$1,125",
                    long: "25.7744356", 
                    lat: "-80.1895185")


puts "Success"