should = require 'should'
{ expect } = require 'chai'
__ = require '../root'
_ = require './utils_builder'

preq = __.require 'lib', 'preq'

# muting unhandled errors
Promise.onPossiblyUnhandledRejection (err)->
  console.log 'unhandledRejection', err

describe 'preq', ->
  describe 'resolved', (done)->
    it 'should be a resolved promise', (done)->
      preq.resolved.should.be.an.Object
      preq.resolved.then.should.be.a.Function
      preq.resolved.catch.should.be.a.Function
      preq.resolved.then -> done()

    it 'should not be modifiable', (done)->
      preq.resolved.wat = 'yo'
      expect(preq.resolved.wat).to.be.undefined
      done()

    it 'should be usable as different promise chain starter', (done)->

      # use it to avoid accessing it to early, while it might not have
      # endured the undesired side effects
      getResolved = -> preq.resolved

      getResolved()
      .then -> return "I'm your father"
      .then -> throw new Error('NoooOooOooooOooOOo')
      .catch (err)->
        console.log 'gotcha!', err
        throw new Error('oups')

      later = ->
        getResolved()
        .catch (err)-> throw new Error "shouldn't be triggered"
        .then (res)->
          expect(res).to.be.undefined
          done()

      setTimeout(later, 100)
