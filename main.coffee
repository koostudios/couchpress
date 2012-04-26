# Requires and Variables
exp = require 'express'
app = exp.createServer()
pass = require 'passport'
Local = require('passport-local').Strategy
config = require('./config').config

# Controllers
posts = require('./controllers/posts').posts
users = require('./controllers/users').users

pass.serializeUser (user, done) ->
	done null, user._id
	
pass.deserializeUser (id, done) ->
	users.findId id, (err, docs) ->
		done err, docs
		
pass.use 'local', new Local (username, password, done) ->
	process.nextTick () ->
		users.find username, password, done
		
# Theme Paths
admin = __dirname + '/views/' + config.theme.admin + '/'
front = __dirname + '/views/' + config.theme.front + '/'

# App Configuration
app.configure () ->
    app.set 'view engine', 'jade'
    app.set 'views', __dirname + '/views'
    app.use '/admin', exp.static admin + '/public'
    app.use exp.static front + '/public'
    app.use exp.cookieParser()
    app.use exp.bodyParser()
    app.use exp.methodOverride()
    app.use exp.session {secret: config.site.secret}
    app.use pass.initialize()
    app.use pass.session()
    app.use app.router
 
# Run App
app.listen config.site.port
console.log 'Server running at port ' + app.address().port

# Routing
app.get '/', (req, res) ->
	posts.findAll (err, docs) ->
        res.render front + 'index',
            locals:
            	title: config.site.title + ' / Home'
            	articles: docs
            	config: config

app.get '/view/:id?', (req, res, next) ->
	posts.findById req.params.id, (err, docs) ->
		res.render front + 'view',
			locals:
				title: config.site.title + ' / ' + docs.title
				article: docs
				config: config

app.get '/login', (req, res) ->
	res.render front + 'login',
		locals:
			title: config.site.title + ' / Login'
			message: req.flash('error')
			config: config
				
app.post '/login', pass.authenticate 'local',
	successRedirect: '/admin'
	failureRedirect: '/login'
	failureFlash: true
	
app.get '/register', (req, res) ->
	res.render front + 'register',
		title: config.site.title + ' / Register'
		config: config
			
app.post '/register', (req, res) ->
	data =
		_id: 'org.couchdb.user:'+ req.param 'username'
		name: req.param 'username'
		password: req.param 'password'
		email: req.param 'email'
		roles: []
		type: 'user'
	users.register data, (err,docs) ->
		if err
			res.render front + 'register',
				locals:
					title: config.site.title + ' / Register'
					message: JSON.stringify err
					config: config
		else
			res.redirect '/admin'

app.get '/logout', (req, res) ->
	req.logOut()
	res.redirect '/'
	
app.get '/admin', users.check, (req, res) ->
	posts.findAll (err, docs) ->
		res.render admin + 'posts',
			layout: admin + 'layout'
			locals:
				title: 'Posts'
				articles: docs

app.get '/admin/new', users.check, (req, res) ->
	res.render admin + 'new',
		layout: admin + 'layout',
		locals:
			title: 'New'
			config: config

app.get '/admin/edit/:id?', users.check, (req, res) ->
	posts.findById req.params.id, (err, docs) ->
		res.render admin + 'editor',
			layout: admin + 'layout'
			locals:
				title: 'Edit'
				article: docs
				config: config

app.post '/admin/new', users.check, (req, res) ->
	docs = 
		title: req.param 'title'
		body: ''
	res.render admin + 'new'
		layout: admin + 'layout',
		locals:
			title: 'New'
			article: docs

app.post '/admin/edit', users.check, (req, res) ->
	if (req.param 'slug')
		slug = req.param 'slug'
	else
		slug = sluggify req.param 'title'
	posts.save {
		_id: slug
		title: req.param 'title'
		body: req.param 'body'
		_rev: req.param 'rev'
		created_at: new Date()
	}, (err, docs) ->
		if (err)
			res.render admin + 'error'
				layout: admin + 'layout'
				locals:
					title: 'Error'
					error: JSON.stringify(err)
		else
			res.redirect('/')
        	
# Other Functions
sluggify = (title) ->
	slug = title.slice(0,30).replace(/\ /ig, '-').toLowerCase()