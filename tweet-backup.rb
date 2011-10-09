#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'twitter_oauth'
require 'twitter'
require 'csv'
require 'yaml'

params = YAML.load(File.read(File.join(File.dirname(__FILE__), 'app.yml')))

# Authentication & authorization
client = TwitterOAuth::Client.new(
          :consumer_key => params['consumer_key'],
          :consumer_secret => params['consumer_secret'])

unless params['oauth_token'] && params['oauth_secret']
  rtoken = client.request_token
  puts "Authorize and input PIN number"
  puts rtoken.authorize_url
  pin = gets.chomp
  atoken = client.authorize(
    rtoken.token,
    rtoken.secret,
    :oauth_verifier => pin
  )
  params['oauth_token'] = atoken.token
  params['oauth_secret'] = atoken.secret

  puts "Update app.yml to remember this access token"
  params.each do |k, v|
    puts "#{k.rjust(20)}: #{v}"
  end
  puts
end

# Twitter client
Twitter.configure do |cfg|
  cfg.consumer_key = params['consumer_key']
  cfg.consumer_secret = params['consumer_secret']
  cfg.oauth_token = params['oauth_token']
  cfg.oauth_token_secret = params['oauth_secret']
end

print 'Backup timeline of: '
user = gets.chomp
print 'Output file name (yml): '
output = gets.chomp
print 'Max ID? (you can skip this): '
after_id = gets.chomp

page = 0
all_data = []
while true
  page += 1
  puts "Fetchting page #{page}"
  begin
    options = { :page => page }
    options[:max_id] = (after_id.to_i - 1).to_s unless after_id.empty?

    page_data = Twitter.user_timeline(user, options)
    break if page_data.empty?

    all_data += page_data
    puts "- Min ID: #{page_data.map { |d| d['id_str'].to_i }.min}"
  rescue Exception => e
    puts e.to_s
    break
  end
end

puts "Writing #{output}"
File.open(output, 'w') { |f| f << YAML.dump(all_data) }
