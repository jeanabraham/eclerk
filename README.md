eClerk
==============================

A simple Ruby application, using Sinatra, to automate Evernote tasks through the Evernote Cloud API.

Evernote is an excellent app. eClerk is intended to augment EverNote features with user-specific demands. A new feature that will be added is the maintenence a "Day Planner" notebook which contains a to-do notes for each day. eClerk can be used to automate these note creations rather than having to manually create, and remove notes for past days.

For instance, if I wanted a 7 new Day Planner notes created for the coming week, I can automate it with a click that will leave me the following 7 new notes in the Day Planner notebook:

159 Sunday, 08 Jun   
160 Monday, 09 Jun   
161 Tuesday, 10 Jun   
162 Wednesday, 11 Jun   
163 Thursday, 12 Jun   
164 Friday, 13 Jun   
165 Saturday, 14 Jun

The format of the note titles: &lt;Day of year&gt; &lt;Day of week&gt;, &lt;Day of month&gt; &lt;month&gt;


**_eClerk/evernote_config.rb_** will need to be added once you obtain an Evernote API key
```ruby
# Load libraries required by the Evernote OAuth sample applications
require 'oauth'
require 'oauth/consumer'

# Load Thrift & Evernote Ruby libraries
require "evernote_oauth"

# Client credentials
# Fill these in with the consumer key and consumer secret that you obtained
# from Evernote. If you do not have an Evernote API key, you may request one
# from http://dev.evernote.com/documentation/cloud/
OAUTH_CONSUMER_KEY = "...."
OAUTH_CONSUMER_SECRET = "...."

SANDBOX = true
