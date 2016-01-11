##
# Copyright 2012 Evernote Corporation. All rights reserved.
##
require 'sinatra'
require 'pry'

enable :sessions

# Load our dependencies and configuration settings
$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require "evernote_config.rb"

##
# Verify that you have obtained an Evernote API key
##
before do
  if OAUTH_CONSUMER_KEY.empty? || OAUTH_CONSUMER_SECRET.empty?
    halt '<span style="color:red">Before using this sample code you must edit evernote_config.rb and replace OAUTH_CONSUMER_KEY and OAUTH_CONSUMER_SECRET with the values that you received from Evernote. If you do not have an API key, you can request one from <a href="http://dev.evernote.com/documentation/cloud/">dev.evernote.com/documentation/cloud/</a>.</span>'
  end
end

helpers do
  def auth_token
    session[:access_token].token if session[:access_token]
  end

  def client
    @client ||= EvernoteOAuth::Client.new(token: auth_token, consumer_key:OAUTH_CONSUMER_KEY, consumer_secret:OAUTH_CONSUMER_SECRET, sandbox: SANDBOX)
  end

  def user_store
    @user_store ||= client.user_store
  end

  def note_store
    @note_store ||= client.note_store
  end

  def en_user
    user_store.getUser(auth_token)
  end

  def notebooks
    @notebooks ||= note_store.listNotebooks(auth_token)
  end

  def total_note_count
    filter = Evernote::EDAM::NoteStore::NoteFilter.new
    counts = note_store.findNoteCounts(auth_token, filter, false)
    notebooks.inject(0) do |total_count, notebook|
      total_count + (counts.notebookCounts[notebook.guid] || 0)
    end
  end

  def todayWithoutTime
    today = Time.new
    today = Time.new(today.year,today.month, today.day)
    return today
  end

  #create Time object from string like "234 Sunday, 8 June"
  def parseTime(timeStr)
    dayOfYear = timeStr[0,3]
    startOfYear = Time.new(Time.new.year)
    time = startOfYear + (60*60*24 *(dayOfYear.to_i-1))
    return time
  end

  def findNoteBook (notebookName)
    notebooks = note_store.listNotebooks(auth_token)
      notebooks.each do |notebook|
        if notebook.name == notebookName
          return notebook
        end
      end
    return nil
  end

  def getDayPlannerNotes
    #get "Day Planner" notebook
    dayPlanner = findNoteBook("Day Planner")
    if dayPlanner != nil
      session[:day_planner_guid] = dayPlanner.guid
      #get notes in "Day Planner"
      filter = Evernote::EDAM::NoteStore::NoteFilter.new
      filter.notebookGuid = session[:day_planner_guid]
      resultSpec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new
      resultSpec.includeTitle = true;
      dayPlannerNotesMetadataList = note_store.findNotesMetadata(auth_token, filter, 0, 100, resultSpec)
      return dayPlannerNotesMetadataList
    end
  end

end

##
# Index page
##
get '/' do
  erb :index
end

##
# create planner pages for next 30 days
##
get '/generate' do
    dayPlannerNotesMetadataList = getDayPlannerNotes
    if session[:day_planner_guid] != 0
      today = Time.new
      for i in 0..7
        note = Evernote::EDAM::Type::Note.new
        day = today + (60 * 60 * 24)*i
        #Format of title: 234 Sunday, 8 June
        note.title = day.strftime("%j %A, %d %b")
        note.notebookGuid = session[:day_planner_guid]
        note.content = "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">
        <en-note>  
    <div><en-todo/>Todo #1</div>
    <div><en-todo/>....</div>
    <div><en-todo/>Todo #n</div>
    <br/>
    <br/>
    <b>Day Scribbles</b>:
    <br/>  
        </en-note>
        "
        noteExists = false
        dayPlannerNotes = dayPlannerNotesMetadataList.notes
        dayPlannerNotes.each do |dayPlannerNote|
          if dayPlannerNote.title == note.title
            noteExists = true
          end
        end

        #create note only if it does not exist
        if !noteExists
            note_store.createNote(auth_token, note);
        end
      end
     session[:message] = "New Day Planner notes created successfully!" 
     redirect '/'
    end
end


##
# move pages in planner up until yesterday into a different notebook
##
get '/cleanup' do
    dayPlannerNotesMetadataList = getDayPlannerNotes
    #move notes to respective year notebook for all days before today
    today = Time.new
    dayPlannerForYear = findNoteBook(today.year.to_s)
    #if it does not exist, create one
    if dayPlannerForYear == nil
      notebook = Evernote::EDAM::Type::Notebook.new
      notebook.name = today.year.to_s
      dayPlannerForYear = note_store.createNotebook(auth_token, notebook)
    end
    dayPlannerNotes = dayPlannerNotesMetadataList.notes
    dayPlannerNotes.each do |dayPlannerNote|
      if dayPlannerNote.title!="Scribbles" && parseTime(dayPlannerNote.title) < todayWithoutTime
        note_store.copyNote(auth_token, dayPlannerNote.guid, dayPlannerForYear.guid)
        note_store.deleteNote(auth_token, dayPlannerNote.guid)
      end
    end
    session[:message] = "Outdated Day Planner notes cleared successfully!"
    redirect '/'
end




##
# Reset the session
##
get '/reset' do
  session.clear
  redirect '/'
end

##
# Obtain temporary credentials
##
get '/requesttoken' do
  callback_url = request.url.chomp("requesttoken").concat("callback")
  begin
    session[:request_token] = client.request_token(:oauth_callback => callback_url)
    redirect '/authorize'
  rescue => e
    @last_error = "Error obtaining temporary credentials: #{e.message}"
    erb :error
  end
end

##
# Redirect the user to Evernote for authoriation
##
get '/authorize' do
  if session[:request_token]
    redirect session[:request_token].authorize_url
  else
    # You shouldn't be invoking this if you don't have a request token
    @last_error = "Request token not set."
    erb :error
  end
end

##
# Receive callback from the Evernote authorization page
##
get '/callback' do
  unless params['oauth_verifier'] || session['request_token']
    @last_error = "Content owner did not authorize the temporary credentials"
    halt erb :error
  end
  session[:oauth_verifier] = params['oauth_verifier']
  begin
    session[:access_token] = session[:request_token].get_access_token(:oauth_verifier => session[:oauth_verifier])
    redirect '/list'
  rescue => e
    @last_error = 'Error extracting access token'
    erb :error
  end
end


##
# Access the user's Evernote account and display account data
##
get '/list' do
  begin
    # Get notebooks
    session[:notebooks] = notebooks.map(&:name)
    # Get username
    session[:username] = en_user.username
    # Get total note count
    session[:total_notes] = total_note_count
    erb :index
  rescue => e
    @last_error = "Error listing notebooks wlkejlj: #{e.message}"
    erb :error
  end
end


__END__

@@ index
<html>
<head>
  <title>eClerk - Evernote Task Automation</title>
</head>
<body>
  <a href="/requesttoken">Click here</a> to authenticate this application using OAuth. <br>
  <a href="/generate">Click here</a> to generate <i>Day Planner</i> notes.<br>
  <a href="/cleanup">Click here</a> to cleanup <i>Day Planner</i> notes.<br>

  <h3><%= session[:message] %></h3>

  <!--
  <% if session[:notebooks] %>
  <hr />
  <h3>The current user is <%= session[:username] %> and there are <%= session[:total_notes] %> notes in their account</h3>
  <br />
  <h3>Here are the notebooks in this account:</h3>
  <ul>
    <% session[:notebooks].each do |notebook| %>
    <li><%= notebook %></li>
    <% end %>
  </ul>
  <% end %>
  -->
  
</body>
</html>

@@ error 
<html>
<head>
  <title>eClerk - EverNote task Automation &mdash; Error</title>
</head>
<body>
  <p>An error occurred: <%= @last_error %></p>
  <p>Please <a href="/reset">start over</a>.</p>
</body>
</html>
