# Description:
#   Let hubot track your co-workers' honor points
#
# Configuration:
#   HUBOT_SCOREKEEPER_MENTION_PREFIX
#
# Commands:
#   <name>++ - Increment <name>'s point
#   <name>-- - Decrement <name>'s point
#   scorekeeper - Show scoreboard
#   show scoreboard - Show scoreboard
#   scorekeeper <name> - Show current point of <name>
#   what's the score of <name> - Show current point of <name>
#
# Author:
#   yoshiori

class Scorekeeper
  _prefix = "scorekeeper"

  constructor: (@robot) ->
    @_scores = null

  increment: (user, func) ->
    scores = @_getScore()
    scores[user] = scores[user] or 0
    scores[user]++
    @_save()
    @score user, func

  decrement: (user, func) ->
    scores = @_getScore()
    scores[user] = scores[user] or 0
    scores[user]--
    @_save()
    @score user, func

  score: (user, func) ->
    scores = @_getScore()
    func false, scores[user] or 0

  rank: (func)->
    scores = @_getScore()
    ranking = (for name, score of scores
      [name, score]
    ).sort (a, b) -> b[1] - a[1]
    func false, (for i in ranking
      i[0]
    )

  _getScore: -> {
    if (@_scores) {
      return @_scores
    }
    json = @robot.brain.get _prefix
    json = json or '{}'
    @_scores = JSON.parse json
    return @_scores
  }

  _save: ->
    scores = @_getScore()
    scores_json = JSON.stringify scores
    @robot.brain.set _prefix, scores_json


module.exports = (robot) ->
  scorekeeper = new Scorekeeper robot
  mention_prefix = process.env.HUBOT_SCOREKEEPER_MENTION_PREFIX || "@"
  mention_prefix_matcher = new RegExp("^#{mention_prefix}")
  mention_suffix = process.env.HUBOT_SCOREKEEPER_MENTION_SUFFIX || ":"
  mention_suffix_matcher = new RegExp("#{mention_suffix}$")
  
  userName = (user) ->
    user = user.trim()
    user = user.replace(mention_prefix_matcher, "")
    user = user.replace(mention_suffix_matcher, "")
    user

  robot.hear (new RegExp("^\\s?#{mention_prefix}?(\\w+?)#{mention_suffix}?\\s?\\+\\+")), (msg) ->
    user = userName(msg.match[1])
    scorekeeper.increment user, (error, result) ->
      msg.send "incremented #{user} (#{result} pt)"

  robot.hear (new RegExp("^\\s?#{mention_prefix}?(\\w+?)#{mention_suffix}?\\s?\\-\\-")), (msg) ->
    user = userName(msg.match[1])
    scorekeeper.decrement user, (error, result) ->
      msg.send "decremented #{user} (#{result} pt)"

  robot.respond /scorekeeper$|show(?: me)?(?: the)? (?:scorekeeper|scoreboard)$/i, (msg) ->
    scorekeeper.rank (error, result) ->
      msg.send (for rank, name of result
        "#{parseInt(rank) + 1} : #{name}"
      ).join("\n")

  robot.respond /scorekeeper (.+)$|what(?:'s| is)(?: the)? score of (.+)\??$/i, (msg) ->
    user = userName(msg.match[1] || msg.match[2])
    scorekeeper.score user, (error, result) ->
      msg.send "#{user} has #{result} points"
