eClerk
==============================

A simple Sinatra-based application to automate Evernote tasks using the Evernote Cloud API.

Evernote is an excellent app. eClerk seeks to augment Evernote features with user-specific demands. For instance, the maintenance of a basic "Day Planner" notebook containing daily TODO notes. eClerk can be used to automate these note creations rather than having to manually create, and remove notes for past days.

If I wanted 7 new "Day Planner" notes (like ones below) created for the coming week, I could have them generated with a click:

159 Sunday, 08 Jun   
160 Monday, 09 Jun   
161 Tuesday, 10 Jun   
162 Wednesday, 11 Jun   
163 Thursday, 12 Jun   
164 Friday, 13 Jun   
165 Saturday, 14 Jun

The format of the note titles: &lt;Day of year&gt; &lt;Day of week&gt;, &lt;Day of month&gt; &lt;month&gt;


**_eClerk/evernote_config.rb_** will need to be updated with your Evernote API key (OAUTH_CONSUMER_KEY, OAUTH_CONSUMER_SECRET)
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
