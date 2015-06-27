# Description
#   Ingress helper commands for Hubot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_GOOGLE_GEOCODE_KEY (optional, may be needed if no results are returned)
#
# Commands:
#   hubot intelmap for <search>
#   https://www.ingress.com/intel?ll=<lat>,<lng> - Return Google Maps image and link for intelmap location
#

module.exports = (robot) ->
  # Setting this on robot so that it can be overridden in test. Is there a better way?
  robot.googleGeocodeKey = process.env.HUBOT_GOOGLE_GEOCODE_KEY
  googleGeocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json'

  lookupLatLong = (msg, location, cb) ->
    params =
      address: location
    params.key = robot.googleGeocodeKey if robot.googleGeocodeKey?

    msg.http(googleGeocodeUrl).query(params)
      .get() (err, res, body) ->
        try
          body = JSON.parse body
          result =
            address: body.results[0].formatted_address
            coords: body.results[0].geometry.location
        catch err
          err = "Could not find #{location}"
          return cb(err, msg, null)
        cb(err, msg, result)

  intelmapUrl = (result) ->
    return result.address + "\nhttps://www.ingress.com/intel?ll=" + encodeURIComponent(result.coords.lat) + "," + encodeURIComponent(result.coords.lng) + "&z=16"

  sendIntelLink = (err, msg, result) ->
    return msg.send err if err
    url = intelmapUrl result
    msg.send url

  gmapImageUrl = (latlng) ->
    return "https://maps.googleapis.com/maps/api/staticmap?center=" + latlng + "&size=400x300&zoom=15&markers=" + latlng

  sendGmapImageLink = (msg, result) ->
    url = gmapImageUrl result
    msg.send url

  gmapLink = (latlng) ->
    return "https://maps.google.com/maps?ll=" + latlng + "&q=" + latlng

  sendGmapLink = (msg, result) ->
    url = gmapLink result
    return msg.send url

  robot.respond /(intelmap|intel map)(?: for)?\s(.*)/i, (msg) ->
    location = msg.match[2]
    lookupLatLong msg, location, sendIntelLink

  robot.hear /https:\/\/www.ingress.com\/intel\?ll=(-?\d+\.\d+,-?\d+\.\d+)/, (msg) ->
    latlng = msg.match[1]
    sendGmapImageLink msg, latlng
    sendGmapLink msg, latlng
