#!/usr/bin/ruby
require 'json'
require 'net/http'
require 'time'

def shutter(speed)
xml = '<?xml version="1.0" encoding="UTF-8"?>' \
             '<Shutter version="1.0" xmlns="http://www.hikvision.com/ver10/XMLSchema">' \
             '<ShutterLevel>' + speed + '</ShutterLevel>' \
             '</Shutter>'
end

def overlay(enabled, message)
xml = '<?xml version="1.0" encoding="UTF-8"?>' \
             '<TextOverlay version="1.0" xmlns="http://www.hikvision.com/ver10/XMLSchema">' \
             '<id>1</id>' \
             '<enabled>' + enabled + '</enabled>' \
             '<posX>16</posX>' \
             '<posY>0</posY>' \
             '<message>' + message + '</message>' \
             '</TextOverlay>'
end

@cameras = ['frontcam.shortbus.lan', 'backcam.shortbus.lan', 'drivewaycam.shortbus.lan']
@key = ENV['wundergroundkey']
@username = ENV['hikvisionuser']
@password = ENV['hikvisionpassword']
@overlayPath = '/Video/inputs/channels/1/overlays/text/1'
@shutterPath = '/Image/channels/1/Shutter'
astronomy_path = '/astronomy/q/KY/40071.json'
condition_path = '/geolookup/conditions/q/KY/40071.json'

def getWeather (path)
  url = 'http://api.wunderground.com/api/' + @key + path
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  JSON.parse(response.body)
end

astronomy = getWeather(astronomy_path)
condition = getWeather(condition_path)

sunrise = astronomy["sun_phase"]["sunrise"]["hour"] + astronomy["sun_phase"]["sunrise"]["minute"]
sunset = astronomy["sun_phase"]["sunset"]["hour"] + astronomy["sun_phase"]["sunset"]["minute"]
now = Time.now.hour.to_s + Time.now.min.to_s

def putCamera camera, path, data
  url = 'http://' + camera + path
  uri = URI.parse url
  request = Net::HTTP::Put.new uri.path
  request.body = data
  request.content_type = 'application/xml'
  request.basic_auth @username, @password
  response = Net::HTTP.new(uri.host, uri.port).start { |http| http.request request }
  response.code
end

def sunup
  overlay_xml = overlay('true', 'Nightime')
  shutter_xml = shutter("1/30")
  @cameras.each do |camera|
    putCamera(camera, @overlayPath, overlay_xml)
    putCamera(camera, @shutterPath, shutter_xml)
  end
end

def sundown
end

##WIP
if now > sunrise && now < sunset
  sunup
else
  sundown
end
