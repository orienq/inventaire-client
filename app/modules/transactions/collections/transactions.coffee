module.exports = Backbone.Collection.extend
  model: require '../models/transaction'
  comparator: (transaction)-> - transaction.get 'created'
