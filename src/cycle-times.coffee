# Description:
#   Calculate Speticycle times.
#
# Dependencies:
#   Moment-timezone.js
#
# Configuration:
#   HUBOT_CYCLE_TIME_FMT: set the display format for times (uses Moment-timezone.js)
#   HUBOT_CYCLE_TZ_OFFSET: set the timezone offset (uses Moment-timezone.js)
#   HUBOT_CYCLE_TZ_NAME: set the timezone name (uses Moment-timezone.js) (name wins if set)
#
# Commands:
#   hubot septicycle|cycle [count]
#   hubot checkpoint|cp [count]
#   hubot cycle offset
#   hubot cycle set offset [offset]
#   hubot cycle set offsetname [offset name]
#   hubot checkpoints|cps on [date] [timezone]
#   hubot mindunits|mindunit|mu average [ours]|[ours]k [theirs]|theirs]k
#   hubot mindunits|mindunit|mu needed [ours]|[ours]k [theirs]|theirs]k
#
# Author:
#   impleri

moment = require "moment-timezone"

# Environment variables
dayFormat = process.env.HUBOT_CYCLE_DAY_FMT or "ddd"
dateFormat = process.env.HUBOT_CYCLE_DAY_FMT or "ddd, MMMM Do YYYY"
timeFormat = process.env.HUBOT_CYCLE_TIME_FMT or "hA"
daytimeFormat = process.env.HUBOT_CYCLE_DAYTIME_FMT or "#{dayFormat} #{timeFormat}"
tzOffset = process.env.HUBOT_CYCLE_TZ_OFFSET or moment().format("Z")
tzName = process.env.HUBOT_CYCLE_TZ_NAME

# Basic variables
checkpoint = 5 * 60 * 60 # 5 hours per checkpoint
checkpointsInCycle = 35
cycle = checkpoint * checkpointsInCycle
seconds = 1000

localizeTime = (time) ->
    if tzName then moment(time).tz tzName else moment(time).utcOffset tzOffset

formatTime = (time, format = daytimeFormat) ->
    m = localizeTime time
    m.format " #{format}"

calculateSomeCycle = (whenish, next = 1) ->
    start = seconds * cycle * Math.floor whenish / (cycle * seconds)
    start + cycle * seconds * next

calculateNextCycle = (next = 1) ->
    calculateSomeCycle new Date().getTime(), next

getNextCycle = (next = 1, format = daytimeFormat) ->
    formatTime calculateNextCycle next, format

calculateSomeCheckpoint = (whenish, next = 1) ->
    start = checkpoint * seconds * Math.floor whenish / (checkpoint * seconds)
    start + checkpoint * seconds * next

calculateNextCheckpoint = (next = 1) ->
    calculateSomeCheckpoint new Date().getTime(), next

getSomeCheckpoint = (whenish, next = 1, format = daytimeFormat) ->
    time = calculateSomeCheckpoint whenish, next
    formatTime time, format

getNextCheckpoint = (next = 1) ->
    formatTime calculateNextCheckpoint next

getCheckpointsDone = () ->
    t0 = new Date('Wed, 08 Jan 2014 03:00:00 +0000');
    t = new Date();
    currentCheckpointNumber = Math.floor((t - t0) / (seconds * checkpoint)) % checkpointsInCycle

getCheckpointsRemaining = () ->
    checkpointsDone = getCheckpointsDone()
    checkpointsRemaining = checkpointsInCycle - checkpointsDone

calculateMuDifference = (ours, theirs) ->
    startCycle = calculateNextCycle 0
    lastCheckpoint = calculateNextCheckpoint 0
    timeElapsed = (lastCheckpoint - startCycle) / seconds
    checkpointsDone = timeElapsed / checkpoint
    ourScore = checkpointsDone * ours
    theirScore = checkpointsDone * theirs
    difference = theirScore - ourScore
    difference = -difference if difference < 1
    difference + 1

getMuNeededNow = (ours, theirs) ->
    calculateMuDifference ours, theirs

getMuNeededAverage = (ours, theirs) ->
    checkpointsRemaining = getCheckpointsRemaining()
    difference = calculateMuDifference ours, theirs
    Math.ceil difference / checkpointsRemaining

module.exports = (robot) ->
  robot.respond /cycle offset/i, (msg) ->
    offset = tzName or tzOffset
    msg.send "Current timezone offset is #{offset}."

  robot.respond /cycle set offset (.*)/i, (msg) ->
    tzOffset = msg.match[1]
    msg.send "Timezone offset is set to #{tzOffset}. I hope you know what you are doing."

  robot.respond /cycle set offsetname (.*)/i, (msg) ->
    tzName = msg.match[1]
    msg.send "Timezone offset name is set to #{tzName}. I hope you know what you are doing."

  robot.respond /(septi)?cycle\s*([0-9])?$/i, (msg) ->
    count = +msg.match[2]
    count = 1 unless count > 1
    times = []
    times.push getNextCycle number for number in [1..count]
    msg.send "The next #{count} cycle(s) occur at: #{times}."

  robot.respond /c(heck)?p(oint)?(\s+[0-9]+)?$/i, (msg) ->
    count = +msg.match[3]
    count = 1 unless count > 1
    times = []
    times.push getNextCheckpoint number for number in [1..count]
    msg.send "The next #{count} checkpoint(s) occur at: #{times}."

  robot.respond /c(heck)?p(oint)?s\s+on\s+((this|next)\s+)?([a-z]+day)/i, (msg) ->
    today = localizeTime moment()
    whenish = today.clone().day(msg.match[5]).startOf "day"
    unless whenish.isAfter today
        whenish.add 7, "days"
    day = formatTime whenish, dateFormat

    whenish.subtract 1, "minute"
    times = []
    times.push getSomeCheckpoint whenish, number, timeFormat for number in [1..5]
    msg.send "The checkpoints on #{day} occur at: #{times}."

  robot.respond /c(heck)?p(oint)?s on (.*)/i, (msg) ->
    return if msg.match[3].match /day$/i
    today = localizeTime moment().isoWeekday()
    whenish = localizeTime(new Date(msg.match[3])).startOf "day"
    day = formatTime whenish, dateFormat

    whenish.subtract 1, "minute"
    times = []
    times.push getSomeCheckpoint whenish, number, timeFormat for number in [1..5]
    msg.send "The checkpoints on #{day} occur at: #{times}."

  robot.respond /m(ind\s*)?u(nits?)?( needed)?\s+([0-9]+k?)\s+([0-9]+k?)/i, (msg) ->
    ours = +msg.match[4]
    ours = 1000 * +msg.match[4].slice 0, -1 if "k" is msg.match[4].slice -1
    ours = 0 unless ours > 0
    theirs = +msg.match[5]
    theirs = 1000 * +msg.match[5].slice 0, -1 if "k" is msg.match[5].slice -1
    theirs = 0 unless theirs > 0
    needed = getMuNeededNow ours, theirs

    if ours > theirs
      winning = 'RES'
      losing = 'ENL'
    else
      winning = 'ENL'
      losing = 'RES'

    checkpointsDone = getCheckpointsDone()
    checkpointsRemaining = getCheckpointsRemaining()
    nextCheckpoint = getNextCheckpoint 1

    if checkpointsDone == 0
      summary = "No checkpoints have been completed in this cycle, please check back after #{nextCheckpoint}."
    else
      summary = "Current ENL score: #{theirs.toLocaleString()}\n" +
                "Current RES score: #{ours.toLocaleString()}\n" +
                "Checkpoints Done: #{checkpointsDone}\n" +
                "Checkpoints Remaining: #{checkpointsRemaining}\n" +
                "Next Checkpoint: #{nextCheckpoint}\n" +
                "\n" +
                "#{losing} needs #{needed.toLocaleString()} total MU to win the cycle in the next checkpoint, " +
                "assuming #{winning} score doesn't change."

    msg.send summary

  robot.respond /m(ind\s*)?u(nits?)? average\s+([0-9]+k?)\s+([0-9]+k?)/i, (msg) ->
    ours = +msg.match[3]
    ours = 1000 * +msg.match[3].slice 0, -1 if "k" is msg.match[3].slice -1
    ours = 0 unless ours > 0
    theirs = +msg.match[4]
    theirs = 1000 * +msg.match[4].slice 0, -1 if "k" is msg.match[4].slice -1
    theirs = 0 unless theirs > 0
    needed = getMuNeededAverage ours, theirs
    checkpointsRemaining = getCheckpointsRemaining()

    if ours > theirs
      winning = 'RES'
      losing = 'ENL'
    else
      winning = 'ENL'
      losing = 'RES'

    checkpointsDone = getCheckpointsDone()
    checkpointsRemaining = getCheckpointsRemaining()
    nextCheckpoint = getNextCheckpoint()

    if checkpointsDone == 0
      summary = "No checkpoints have been completed in this cycle, please check back after #{nextCheckpoint}."
    else
      summary = "Current ENL score: #{theirs.toLocaleString()}\n" +
                "Current RES score: #{ours.toLocaleString()}\n" +
                "Checkpoints Done: #{checkpointsDone}\n" +
                "Checkpoints Remaining: #{checkpointsRemaining}\n" +
                "Next Checkpoint: #{nextCheckpoint}\n" +
                "\n" +
                "#{losing} needs #{needed.toLocaleString()} MU per checkpoint in the remaining #{checkpointsRemaining} checkpoint(s) to win the cycle, " +
                "assuming #{winning} score doesn't change."

    msg.send summary
