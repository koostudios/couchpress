cradle = require 'cradle'
moment = require 'moment'
fs     = require 'fs'
config = require('../config').config

class Upload
	constructor: (host, port) ->
		@connect = new cradle.Connection config.db.host, config.db.port, {
			cache: true
			raw: false
		}
		@db = @connect.database 'couchpress'

	findAll: (callback) ->
		@db.view 'couchpress/uploads_all', {descending: true}, (err, res) ->
			if (err)
				callback err
			else
				docs = []
				res.forEach (row) ->
					row.created_at = moment(row.created_at).fromNow()
					docs.push row
				callback null, docs

	findById: (slug, filename, callback) ->
		thatdb = @db
		thatdb.get slug, (err, doc) ->
			stream = thatdb.getAttachment slug, filename
			data = []
			dataLen = 0
			stream.on 'data', (chunk) ->
				data.push chunk
				dataLen += chunk.length
			stream.on 'end', ->
				buf = new Buffer(dataLen)
				pos = 0
				for chunk in data
					chunk.copy buf, pos
					pos += chunk.length
				doc.data = buf;
				callback(null, doc)

	save: (article, reqfile, callback) ->
		thatdb = @db
		article.type = 'upload'
		article.created_at = new Date()
		article.size = reqfile.size
		fs.readFile reqfile.path, (err, data) ->
			article._attachments = {}
			article._attachments[article.filename] = {
				content_type: reqfile.type
				data: data.toString('base64')
			}
			thatdb.save article, (err, res) ->
				if (err)
					callback(err)
				else
					callback(null, res)


exports.uploads = new Upload()