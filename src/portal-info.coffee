# Description:
#   Provides details about portal builds
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   portal distance [resos]
#   distance from/between [intel link] to/and [intel link]
#
# Author:
#   snotrocket

# global module
module.exports = (robot) ->
  getDistanceInMeters = (p1, p2) ->

	# Returns the distance (in meters) between two points
	# From http://stackoverflow.com/a/1502821
	rad = undefined
	R = undefined
	dLat = undefined
	dLng = undefined
	a = undefined
	c = undefined
	d = undefined
	rad = (x) ->
	  x * Math.PI / 180

	R = 6378137 # Earth’s mean radius in meter
	dLat = rad(p2.lat - p1.lat)
	dLng = rad(p2.lng - p1.lng)
	a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(rad(p1.lat)) * Math.cos(rad(p2.lat)) * Math.sin(dLng / 2) * Math.sin(dLng / 2)
	c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
	d = R * c
	d # returns the distance in meter


  # calculates portal link distance in km for a given portal level
  portalRange = (level, la) ->
	d = 160.0 * Math.pow(level, 4) / 1000
	switch la
	  when 1
		d *= 2.0
	  when 2
		d *= 2.5
	  when 3
		d *= 2.75
	  when 4
		d *= 3.0
	+d.toFixed(4)


  # calculate portal distance
  robot.respond /portal\sdistance\s([1-8]{1,8})(\swith\s([1-4])\s?(la|link amp)s?)?$/i, (msg) ->
	q = msg.match[1]
	la = +msg.match[3]
	resos = q.split("").map((n) ->
	  +n
	)
	level = resos.reduce((a, b) ->
	  a + b
	) / 8
	distance = portalRange(level, la)
	message = "P" + Math.floor(level) + " (" + q + ")"
	if la
	  message += " with " + la + " link amp"
	  message += "s"  if la > 1
	message += " link distance is " + distance + " km"
	msg.send message


  # calculate distance between portals
  robot.respond /distance\s?(between|from)?\shttps:\/\/www.ingress.com\/intel\?ll=([-0-9.]+),([-0-9.]+)((&z=\d+)?&pll=([-0-9.]+),([-0-9.]+))?\s?(and|to)?\s?https:\/\/www.ingress.com\/intel\?ll=([-0-9.]+),([-0-9.]+)((&z=\d+)?&pll=([-0-9.]+),([-0-9.]+))?/i, (msg) ->
	a = {}
	b = {}
	distance = undefined
	message = undefined
	a.lat = +(msg.match[6] or msg.match[2])
	a.lng = +(msg.match[7] or msg.match[3])
	b.lat = +(msg.match[13] or msg.match[9])
	b.lng = +(msg.match[14] or msg.match[10])
	distance = getDistanceInMeters(a, b)
	distance = +(distance / 1000).toFixed(3)
	message = "Distance between (" + a.lat + ", " + a.lng + ") and (" + b.lat + ", " + b.lng + ") is " + distance + " km"
	msg.send message