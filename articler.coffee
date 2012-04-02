# Articler Class - Handles all article functions
cradle = require 'cradle'
moment = require 'moment'
 
class Articler
    constructor: (host, port) ->
        @connect = new cradle.Connection host, port, {
            cache: true
            raw: false
        }
        @db = @connect.database 'couchpress'
 
    findAll: (callback) ->
        @db.view 'couchpress/all', {descending: true}, (err, res) ->
            if (err)
                callback err
            else
                docs = []
                res.forEach (row) ->
                	row.created_at = moment(row.created_at).fromNow()
                	docs.push row
                callback null, docs
    
    findById: (id, callback) ->
        @db.get id, (err,res) ->
            if (err)
                callback err
            else 
                res.created_at = moment(res.created_at).fromNow()
                callback null, res
 
    save: (articles, callback) ->
        @db.save articles, (err, res) ->
            if (err)
                callback err
            else
                callback null, articles
 
exports.Articler = Articler