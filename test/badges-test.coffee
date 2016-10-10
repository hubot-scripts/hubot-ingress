chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'ingress: badges', ->
  user =
    name: 'user'
    id: 'U123'
  robot =
    respond: sinon.spy()
    hear: sinon.spy()
    brain:
      on: (_, cb) ->
        cb()
      data: {}
      userForName: (who) ->
        forName =
          name: who
          id: 'U234'

  beforeEach ->
    @user = user
    @robot = robot
    @data = @robot.brain.data
    @msg =
      send: sinon.spy()
      reply: sinon.spy()
      envelope:
        user:
          @user
      message:
        user:
          @user

  require('../src/badges')(robot)

  it 'registers "have badge" listener', ->
    expect(@robot.respond).to.have.been.calledWith(/(@?[.\w\-]+) (?:have|has|got|earned)(?: the)? :?([\-\w,\s]+):? badges?/i)

  it 'registers "what badges" listener', ->
    expect(@robot.respond).to.have.been.calledWith(/wh(?:at|ich) badges? do(?:es)? (@?[.\w\-]+) have/i)

  it 'registers "do not have" listener', ->
    expect(@robot.respond).to.have.been.calledWith(/(@?[.\w\-]+) (?:do(?:n't|esn't| not)) have the :?([\-\w]+):? badge/i)

  it 'responds to "I have the founder badge"', ->
    @msg.match = [0, 'I', 'founder']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(@msg.reply).to.have.been.calledWith('congrats on earning the :founder: badge!')
    expect(badges).to.be.a('array')
    expect(badges).to.include(':founder:')

  it 'responds to "I have the oliver-lynton-wolfe badge"', ->
    @msg.match = [0, 'I', 'oliver-lynton-wolfe']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(@msg.reply).to.have.been.calledWith('congrats on earning the :oliver-lynton-wolfe: badge!')
    expect(badges).to.be.a('array')
    expect(badges).to.include(':oliver-lynton-wolfe:')

  it 'responds to "I have the black guardian badge"', ->
    @msg.match = [0, 'I', 'black guardian']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(@msg.reply).to.have.been.calledWith('congrats on earning the :guardian5: badge!')
    expect(badges).to.be.a('array')
    expect(badges).to.include(':guardian5:')

  it 'responds to "I have the guardian badge"', ->
    @msg.match = [0, 'I', 'guardian']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(@msg.reply).to.have.been.calledWith('congrats on earning the :guardian1: badge!')
    expect(badges).to.be.a('array')
    expect(badges).to.include(':guardian1:')

  it 'responds with error message on invalid badge name', ->
    @msg.match = [0, 'I', 'random']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(@msg.reply).to.have.been.calledWith('invalid badge name(s): random1.')
    expect(badges).to.be.a('array')
    expect(badges).not.to.include(':random1:')

  it '"I have" automatically replaces badge of same type', ->
    @msg.match = [0, 'I', 'hacker1']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(@msg.reply).to.have.been.calledWith('congrats on earning the :hacker1: badge!')
    expect(badges).to.be.a('array')
    expect(badges).to.include(':hacker1:')
    @msg.match = [0, 'I', 'hacker2']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(@msg.reply).to.have.been.calledWith('congrats on earning the :hacker2: badge!')
    expect(badges).to.be.a('array')
    expect(badges).not.to.include(':hacker1:')
    expect(badges).to.include(':hacker2:')

  it '"I have" can handle multiple badge names', ->
    @msg.match = [0, 'I', 'pioneer3, hacker4, builder1, oliver-lynton-wolfe']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(@msg.reply).to.have.been.calledWith(sinon.match(/congrats on earning the .* badges!/))
    expect(badges).to.be.a('array')
    expect(badges).to.include(':pioneer3:')
    expect(badges).to.include(':hacker4:')
    expect(badges).to.include(':builder1:')
    expect(badges).to.include(':oliver-lynton-wolfe:')
  
  it '"I have" can handle multiple character badges when the respective character has an old and new badge', ->
    @msg.match = [0, 'I', 'susanna-moyer1, susanna-moyer2']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(badges).to.be.a('array')
    expect(badges).to.include(':susanna-moyer1:')
    expect(badges).to.include(':susanna-moyer2:')
    
  it '"I have" doesn\'t attempt to add an anomaly or character badge that has already been added', ->
    @msg.match = [0, 'I', 'shonin']
    @robot.respond.args[0][1](@msg)
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U123
    expect(badges).to.be.a('array')
    expect(badges).to.include(':shonin:')
    expect(badges).to.satisfy((bdgs) -> (bdgs.filter (x) -> x == ':shonin:').length == 1)

  it 'responds to "user2 has the verified badge"', ->
    @msg.match = [0, 'user2', 'verified']
    @robot.respond.args[0][1](@msg)
    badges = @data.ingressBadges.U234
    expect(@msg.send).to.have.been.calledWith('@user2: congrats on earning the :verified: badge!')
    expect(badges).to.be.a('array')
    expect(badges).to.include(':verified:')

  it 'responds to "what badges do I have"', ->
    @msg.match = [0, 'I']
    @robot.respond.args[1][1](@msg)
    expect(@msg.reply).to.have.been.calledWith(sinon.match(/You have (the following|no) badges.*/))

  it 'responds to "what badges does user2 have"', ->
    @msg.match = [0, 'user2']
    @robot.respond.args[1][1](@msg)
    expect(@msg.reply).to.have.been.calledWith(sinon.match(/user2 has (the following|no) badges.*/))

  it 'responds to "I don\'t have the founder badge"', ->
    @msg.match = [0, 'I', 'founder']
    @robot.respond.args[2][1](@msg)
    badges = @data.ingressBadges.U123
    expect(@msg.reply).to.have.been.calledWith('removed the :founder: badge')
    expect(badges).not.to.include(':founder:')
  
  describe 'handles usernames with special characters [@-.]', ->
    it '(user-2)', ->
      @msg.match = [0, 'user-2', 'verified']
      @robot.respond.args[0][1](@msg)
      badges = @data.ingressBadges.U234
      expect(badges).to.be.a('array')
      expect(badges).to.include(':verified:')
      expect(@msg.send).to.have.been.calledWith('@user-2: congrats on earning the :verified: badge!')
    it '(user.2)', ->
      @msg.match = [0, 'user.2', 'verified']
      @robot.respond.args[0][1](@msg)
      badges = @data.ingressBadges.U234
      expect(badges).to.be.a('array')
      expect(badges).to.include(':verified:')
      expect(@msg.send).to.have.been.calledWith('@user.2: congrats on earning the :verified: badge!')
    it '(@user2)', ->
      @msg.match = [0, '@user2', 'verified']
      @robot.respond.args[0][1](@msg)
      badges = @data.ingressBadges.U234
      expect(badges).to.be.a('array')
      expect(badges).to.include(':verified:')
      expect(@msg.send).to.have.been.calledWith('@user2: congrats on earning the :verified: badge!')
