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