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
#   hubot mindunits|mindunit|mu average [RES]|[RES]k [ENL]|ENL]k
#   hubot mindunits|mindunit|mu needed [RES]|[RES]k [ENL]|ENL]k
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
    m.format "#{format}"

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

calculateMuDifferenceNextCheckpoint = (RES, ENL) ->
    ###
    getCheckpointsDone() + 1 is to calculate the number
    of completed checkpoints at the NEXT checkpoint
    ###
    checkpointsDoneAtNextCheckpoint = getCheckpointsDone() + 1
    difference = Math.abs(ENL - RES) * checkpointsDoneAtNextCheckpoint

getMusNeededNow = (RES, ENL) ->
    musNeeded = calculateMuDifferenceNextCheckpoint RES, ENL
    ###
    Increment MUs needed by one so that score is not tied
    ###
    ++musNeeded

getMusNeededAverage = (RES, ENL) ->
    ###
    getCheckpointsRemaining() - 1 is to calculate the number
    of remaining checkpoints at the NEXT checkpoint
    (Ensure it is at least 1 to avoid division by zero)
    ###
    checkpointsRemainingAtNextCheckpoint = getCheckpointsRemaining() - 1
    checkpointsRemainingAtNextCheckpoint = 1 unless checkpointsRemainingAtNextCheckpoint > 1
    musNeeded = getMusNeededNow RES, ENL
    Math.ceil musNeeded / checkpointsRemainingAtNextCheckpoint

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
    msg.send "The next #{count} cycle(s) occur at: #{times.join(', ')}."

  robot.respond /c(heck)?p(oint)?(\s+[0-9]+)?$/i, (msg) ->
    count = +msg.match[3]
    count = 1 unless count > 1
    times = []
    times.push getNextCheckpoint number for number in [1..count]
    msg.send "The next #{count} checkpoint(s) occur at: #{times.join(', ')}."

  robot.respond /c(heck)?p(oint)?s\s+on\s+((this|next)\s+)?([a-z]+day)/i, (msg) ->
    today = localizeTime moment()
    whenish = today.clone().day(msg.match[5]).startOf "day"
    unless whenish.isAfter today
        whenish.add 7, "days"
    day = formatTime whenish, dateFormat

    whenish.subtract 1, "minute"
    times = []
    times.push getSomeCheckpoint whenish, number, timeFormat for number in [1..5]
    msg.send "The checkpoints on #{day} occur at: #{times.join(', ')}."

  robot.respond /c(heck)?p(oint)?s on (.*)/i, (msg) ->
    return if msg.match[3].match /day$/i
    today = localizeTime moment().isoWeekday()
    whenish = localizeTime(new Date(msg.match[3])).startOf "day"
    day = formatTime whenish, dateFormat

    whenish.subtract 1, "minute"
    times = []
    times.push getSomeCheckpoint whenish, number, timeFormat for number in [1..5]
    msg.send "The checkpoints on #{day} occur at: #{times.join(', ')}."

  robot.respond /m(ind\s*)?u(nits?)?( needed)?\s+([0-9]+k?)\s+([0-9]+k?)/i, (msg) ->
    checkpointsDone = getCheckpointsDone()
    checkpointsRemaining = getCheckpointsRemaining()
    nextCheckpoint = getNextCheckpoint 1

    RES = +msg.match[4]
    RES = 1000 * +msg.match[4].slice 0, -1 if "k" is msg.match[4].slice -1
    RES = 0 unless RES > 0

    ENL = +msg.match[5]
    ENL = 1000 * +msg.match[5].slice 0, -1 if "k" is msg.match[5].slice -1
    ENL = 0 unless ENL > 0

    if checkpointsDone == 0
      summary = "No checkpoints have been completed in this cycle, please check back after #{nextCheckpoint}."
    else if RES == ENL
      summary = "Score is currently tied, the cycle is up for grabs. Go out and throw more fields!"
    else
      if RES > ENL
        winning = 'RES'
        losing = 'ENL'
      else
        winning = 'ENL'
        losing = 'RES'

      needed = getMusNeededNow RES, ENL

      summary = "Current ENL score: #{ENL.toLocaleString()}\n" +
                "Current RES score: #{RES.toLocaleString()}\n" +
                "Checkpoints Done: #{checkpointsDone}\n" +
                "Checkpoints Remaining: #{checkpointsRemaining}\n" +
                "Next Checkpoint: #{nextCheckpoint}\n" +
                "\n" +
                "#{losing} needs #{needed.toLocaleString()} total MUs to win the cycle in the next checkpoint, " +
                "assuming #{winning} score doesn't change."

    msg.send summary

  robot.respond /m(ind\s*)?u(nits?)? average\s+([0-9]+k?)\s+([0-9]+k?)/i, (msg) ->
    checkpointsDone = getCheckpointsDone()
    checkpointsRemaining = getCheckpointsRemaining()
    nextCheckpoint = getNextCheckpoint()

    RES = +msg.match[3]
    RES = 1000 * +msg.match[3].slice 0, -1 if "k" is msg.match[3].slice -1
    RES = 0 unless RES > 0

    ENL = +msg.match[4]
    ENL = 1000 * +msg.match[4].slice 0, -1 if "k" is msg.match[4].slice -1
    ENL = 0 unless ENL > 0

    if checkpointsDone == 0
      summary = "No checkpoints have been completed in this cycle, please check back after #{nextCheckpoint}."
    else if RES == ENL
      summary = "Score is currently tied, the cycle is up for grabs. Go out and throw more fields!"
    else
      if RES > ENL
        winning = 'RES'
        losing = 'ENL'
      else
        winning = 'ENL'
        losing = 'RES'

      needed = getMusNeededAverage RES, ENL

      summary = "Current ENL score: #{ENL.toLocaleString()}\n" +
                "Current RES score: #{RES.toLocaleString()}\n" +
                "Checkpoints Done: #{checkpointsDone}\n" +
                "Checkpoints Remaining: #{checkpointsRemaining}\n" +
                "Next Checkpoint: #{nextCheckpoint}\n" +
                "\n" +
                "#{losing} needs #{needed.toLocaleString()} MUs per checkpoint in the remaining #{checkpointsRemaining} checkpoint(s) to win the cycle, " +
                "assuming #{winning} score doesn't change."

    msg.send summary
