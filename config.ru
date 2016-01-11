require 'rubygems'
require 'bundler'
Bundler.require

require './en_oauth.rb'
require './evernote_config.rb'
run Sinatra::Application