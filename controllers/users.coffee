cradle = require 'cradle'
crypto = require 'crypto'
config = require('../config').config
admin = require('../config').admin

class User
	constructor: () ->
		@connect = new cradle.Connection config.db.host, config.db.port, {
			cache: true
			raw: false
			auth: {username: admin.user, password: admin.pass}
		}
		@db = @connect.database '_users'
		
	find: (user, pass, done) ->
		@db.get 'org.couchdb.user:'+user, (err, user) ->
			# Error
			if !user || err
				done null, null, {message: '<b>Error:</b> User not found.'}	
			else
				hash = crypto.createHash('sha1').update(pass+user.salt).digest('hex')
				if (hash != user.password_sha)
					done null, null, {message: '<b>Error:</b> Password incorrect.'}
				else
					done null, user

	findId: (id, done) ->
		@db.get id, done
	
	register: (data, done) ->
		@db.save data, (err, user) ->
			done err, user
			
	check: (req, res, next) ->
		if req.isAuthenticated()
			next()
		else
			res.redirect '/login'
			
exports.users = new User()