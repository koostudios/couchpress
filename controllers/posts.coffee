cradle = require 'cradle'
moment = require 'moment'
md = require('node-markdown').Markdown
config = require('../config').config
 
class Post
	constructor: (host, port) ->
		@connect = new cradle.Connection config.db.host, config.db.port, {
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
                    row.rawDate = row.created_at
                    row.created_at = moment(row.created_at).fromNow()
                    docs.push row
                callback null, docs
	
	findById: (id, callback) ->
        @db.get id, (err,res) ->
            if (err)
                callback err
            else
                res.rawDate = res.created_at
                res.created_at = moment(res.created_at).fromNow()
                callback null, res

    findByTag: (tag, callback) ->
        @db.view 'couchpress/tag', {key: tag, descending: true}, (err, res) ->
            if (err)
                callback(err)
            else
                docs = []
                res.forEach (row) ->
                    row.rawDate = row.created_at
                    row.created_at = moment(row.created_at).fromNow()
                    docs.push row
                callback(null, docs)
 	
 	save: (article, callback) ->
        article.body = md(article.markdown)
        article.created_at = new Date()
        @db.save article, (err, res) ->
            if (err)
                callback err
            else
                callback null, article
	
	remove: (id, rev) ->
    	@db.remove id, rev
 
exports.posts = new Post()