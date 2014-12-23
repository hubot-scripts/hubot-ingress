# Description
#   Ingress helper commands for Hubot
#
# Dependencies:
#   None
#
# Commands:
#   hubot I have the <badge> badge - add/remove badges (say don't to remove)
#   hubot I don't have any badges - remove your badges completely
#   hubot what badges do I have? - show off your Ingress badges—you worked hard for them!
#   hubot what badges does <person> have? - check another agent's badges
#
# Author:
#   therealklanni

badgeList = [
  'builder1', 'builder2', 'builder3', 'builder4', 'builder5',
  'connector1', 'connector2', 'connector3', 'connector4', 'connector5',
  'darsana',
  'engineer1', 'engineer2', 'engineer3', 'engineer4', 'engineer5',
  'eve',
  'explorer1', 'explorer2', 'explorer3', 'explorer4', 'explorer5',
  'founder',
  'guardian1', 'guardian2', 'guardian3', 'guardian4', 'guardian5',
  'hacker1', 'hacker2', 'hacker3', 'hacker4', 'hacker5',
  'helios',
  'initio',
  'innovator1', 'innovator2', 'innovator3', 'innovator4', 'innovator5'
  'interitus',
  'liberator1', 'liberator2', 'liberator3', 'liberator4', 'liberator5',
  'mindcontroller1', 'mindcontroller2', 'mindcontroller3', 'mindcontroller4', 'mindcontroller5',
  'oliver-lynton-wolfe',
  'pioneer1', 'pioneer2', 'pioneer3', 'pioneer4', 'pioneer5',
  'purifier1', 'purifier2', 'purifier3', 'purifier4', 'purifier5',
  'recharger1', 'recharger2', 'recharger3', 'recharger4', 'recharger5',
  'recursion',
  'seer1', 'seer2', 'seer3', 'seer4', 'seer5',
  'specops1', 'specops2', 'specops3', 'specops4', 'specops5',
  'trekker1', 'trekker2', 'trekker3', 'trekker4', 'trekker5',
  'verified'
]

module.exports = (robot) ->
  badges =
    add: (user, badgeNames...) ->
      for badgeName in badgeNames
        toRemove = badgeList.filter (x) ->
          (x.replace /\d+/, '') is (badgeName.replace /\d+/, '')
        @del user, badge for badge in toRemove
        userBadges = robot.brain.data.ingressBadges[user.id] ?= []
        userBadges.push ":#{badgeName}:"
    del: (user, badgeName) ->
      robot.brain.data.ingressBadges[user.id] = (badges.forUser user).filter (x) ->
        x isnt ":#{badgeName}:"
    clear: (user) ->
      robot.brain.data.ingressBadges[user.id] = []
    forUser: (user) ->
      robot.brain.data.ingressBadges[user.id] ?= []

  robot.brain.on 'loaded', ->
    robot.brain.data.ingressBadges ?= {}

  robot.respond /(I|@?\w+) (?:have|has|got|earned)(?: the)? :?([\w,\s]+):? badges?/i, (msg) ->
    who = msg.match[1].toLowerCase().replace '@', ''
    badgeNames = (msg.match[2].toLowerCase().replace /\s*/g, '').split ','

    if who == 'i'
      who = msg.envelope.user
    else
      who = robot.brain.userForName who

    invalidNames = []
    for badgeName in badgeNames
      if badgeName not in badgeList
        invalidNames.push badgeName

    msg.reply "invalid badge name(s): #{invalidNames.join ', '}." if invalidNames.length > 0
    badgeNames = badgeNames.filter (x) -> x not in invalidNames

    if badgeNames.length > 0
      for badgeName in badgeNames
        badges.add who, badgeName

      userBadges = badges.forUser who
      badgeNames = badgeNames.filter (x) ->
        ":#{x}:" in userBadges

      if who.name == msg.envelope.user.name
        msg.reply "congrats on earning the :#{badgeNames.join ': :'}:
 badge#{if badgeNames.length > 1 then 's' else ''}!"
      else
        msg.send "@#{who.name}: congrats on earning the :#{badgeNames.join ': :'}:
 badge#{if badgeNames.length > 1 then 's' else ''}!"

  robot.respond /wh(?:at|ich) badges? do(?:es)? (I|@?\w+) have/i, (msg) ->
    who = msg.match[1].replace '@', ''

    if who.toLowerCase() == 'i'
      who = msg.envelope.user
    else
      who = robot.brain.userForName who

    userBadges = badges.forUser who
    you = if who? and who.name == msg.envelope.user.name then true else false
    whowhat = "#{if you then 'You have' else who.name + ' has'}"

    if who? and userBadges.length > 0
      msg.reply "#{whowhat} the following badges: #{userBadges.join ' '}"
    else
      msg.reply "#{whowhat} no badges."

  robot.respond /(I|@?\w+) (?:do(?:n't|esn't| not)) have the :?(\w+):? badge/i, (msg) ->
    who = msg.match[1].toLowerCase().replace '@', ''
    badgeName = msg.match[2].toLowerCase()

    if who == 'i'
      who = msg.envelope.user
    else
      who = robot.brain.userForName who

    if ":#{badgeName}:" in badges.forUser who
      badges.del who, badgeName
      msg.reply "removed the :#{badgeName}: badge"

  robot.respond /I (?:do(?:n't| not)) have any badges?/i, (msg) ->
    badges.clear msg.envelope.user
    msg.reply 'OK, removed all your badges'
