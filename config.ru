require 'rubygems'
require 'bundler'
Bundler.require

require './en_auth.rb'
require './evernote_config.rb'
run Sinatra::Application