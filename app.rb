# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

events_table = DB.from(:events)
rsvps_table = DB.from(:rsvps)
users_table = DB.from(:users)

#Twilio API
account_sid = "AC98e60e0bb63b2572d4e1e5813d50de38"
auth_token = "76db1bf714b419bb6258833dd61fe071"
client = Twilio::REST::Client.new(account_sid, auth_token)


before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end 

get "/" do
    puts "params: #{params}"

    pp events_table.all.to_a
    @events = events_table.all.to_a
    view "home_page"
end

get "/events" do
    puts "params: #{params}"
    
    
    pp events_table.all.to_a
    @events = events_table.all.to_a
    view "events"
end

get "/events/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @event = events_table.where(id: params[:id]).to_a[0]
    pp @event

    @rsvps = rsvps_table.where(event_id: @event[:id]).to_a
    @going_count = rsvps_table.where(event_id: @event[:id], going: true).count

    view "event"
end

get "/events/:id/rsvps/new" do
    puts "params: #{params}"

    @event = events_table.where(id: params[:id]).to_a[0]

    @user_logged_in = users_table.where(id: session["user_id"]).to_a[0] 
    if @user_logged_in 
            #know the user is logged in 
            view "new_rsvp"
        else
            #force user to log in before being able to purchase
            view "new_login"
        end
end

get "/events/:id/rsvps/create" do
    puts "params: #{params}"

    # first find the event that rsvp'ing for 
    @event = events_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the rsvp 
    rsvps_table.insert(
        event_id:@event[:id],   # need to associate what event we are rsvp'ing for, thus we add 'event id'
        user_id: session["user_id"],
        billing_name: params["billing_name"],
        billing_address: params["billing_address"],
        comments: params["comments"], 
        going: params["going"]
    )

    client.messages.create(
        from: "+17479980106", 
        to: "+17142714477",
        body: "Congrats! Your FestivAll reservation is confirmed. Be on the look out for instructions to finalize payment."
    )
    view "create_rsvp"
end



get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    puts "params: #{params}"
    
    # first, is there a user with the params["email"]
    # second, if there is, does the password match?
    @user = users_table.where(email: params["email"]).to_a[0] 
    if @user && BCrypt::Password.new(@user[:password]) == params["password"]
            #know the user is logged in 
            session["user_id"] = @user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
end

get "/logout" do
    session["user_id"] = nil #set this to remove cookies and log user out
    view "logout"
end

# display the rsvp form (aka "edit")
get "/rsvps/:id/edit" do
    puts "params: #{params}"

    @rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    @event = events_table.where(id: @rsvp[:event_id]).to_a[0]
    view "edit_rsvp"
end

# receive the submitted rsvp form (aka "update")
post "/rsvps/:id/update" do
    puts "params: #{params}"

    # find the rsvp to update
    @rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    # find the rsvp's event
    @event = events_table.where(id: @rsvp[:event_id]).to_a[0]

    if @current_user && session["user_id"] = @rsvp[:id]
    
        rsvps_table.where(id: params["id"]).update(
            going: params["going"],
            comments: params["comments"]
        )

        redirect "/events/#{@event[:id]}"
    else
        view "error"
    end
end

get "/rsvps/:id/destroy" do
    puts "params: #{params}"

    rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    @event = events_table.where(id: rsvp[:event_id]).to_a[0]

    rsvps_table.where(id: params["id"]).delete

    view "destroy_rsvp"
end