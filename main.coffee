# Requires and Variables
fs = require 'fs'
exp = require 'express'
pass = require 'passport'
app = exp.createServer()
config = require('./config').config
Local = require('passport-local').Strategy

# Controllers
posts = require('./controllers/posts').posts
users = require('./controllers/users').users
uploads = require('./controllers/uploads').uploads

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

# To reload assets
load = ->
  admin = __dirname + '/views/' + config.theme.admin + '/'
  front = __dirname + '/views/' + config.theme.front + '/'

# App Configuration
app.configure () ->
  app.set 'view engine', 'jade'
  app.set 'views', __dirname + '/views'
  app.set 'view options', { pretty: true }
  app.use '/admin', exp.static admin + '/public'
  app.use exp.static front + '/public'
  app.use exp.cookieParser()
  app.use exp.bodyParser()
  app.use exp.methodOverride()
  app.use exp.session {secret: config.site.secret}
  app.use pass.initialize()
  app.use pass.session()
  app.use app.router

# Exposing config in requests
app.dynamicHelpers
  config : -> config

# Run App
app.listen config.site.port, () ->
  console.log ':: CouchPress running at port ' + app.address().port + ' ::'

# Routing
app.get '/', (req, res) ->
  posts.findAll (err, docs) ->
        res.render front + 'index',
            locals:
              title: config.site.title + ' / Home'
              articles: docs

app.get '/:id?', (req, res, next) ->
  posts.findById req.params.id, (err, docs) ->
    if err
      next()
    else if docs.status != 'draft'
      res.render front + 'view',
        locals:
          title: config.site.title + ' / ' + docs.title
          article: docs
    else
      next()

app.get '/tag/:tag', (req, res) ->
	posts.findByTag req.params.tag, (err, docs) ->
		res.render front + 'index',
			locals:
				title: config.site.title + ' / Tag / ' + req.params.tag
				articles: docs
				config: config

app.get '/login', (req, res) ->
  res.render front + 'login',
    locals:
      title: config.site.title + ' / Login'
      message: req.flash('error')
        
app.post '/login', pass.authenticate 'local',
  successRedirect: '/admin'
  failureRedirect: '/login'
  failureFlash: true
  
app.get '/register', (req, res) ->
  res.render front + 'register',
    title: config.site.title + ' / Register'
      
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
          title: config.site.title
          message: JSON.stringify err
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

app.get '/upload/:slug/:filename', (req, res, next) ->
	uploads.findById req.params.slug, req.params.filename, (err, file) ->
		if err
			next()
		else
			res.header "Content-type", file._attachments[file.filename].content_type
			res.header "Content-Encoding", "identity"
			res.header "Content-length", file.size
			res.end file.data

app.get '/admin/uploads', users.check, (req, res) ->
	uploads.findAll (err, files) ->
		res.render admin + 'uploads',
			layout: admin + 'layout',
			locals:
					title: 'Uploads',
					articles: files

app.post '/admin/uploads', users.check, (req, res) ->
	slug = sluggify req.param 'title'
	filename = sluggify req.files.upload.name
	uploads.save {
		_id: slug
		title: req.param 'title'
		filename: filename
		type: 'upload'
		user: req.user.name

	}, req.files.upload, (err, docs) ->
		if (err)
      console.log(':: CouchPress :: ERROR -> \n' + err)
      res.redirect '/500'
		else
			res.redirect '/admin/uploads'

app.get '/admin/settings', users.check, (req, res) ->
  adminConfig = require('./config').admin
  res.render admin + 'settings',
    layout: admin + 'layout'
    locals:
      title: 'Settings'
      admin: adminConfig

app.post '/admin/settings', users.check, (req, res) ->
  Data = JSON.stringify JSON.parse(req.param('data')), null, 2
  Admin = JSON.stringify JSON.parse(req.param('admin')), null, 2
  template = 'exports.config = ' +  Data + ';\nexports.admin = ' + Admin
  fs.writeFile './config.js', template, 'utf8', (err) ->
    if err
      res.send '<b>Error:</b>' + err
    else
      delete require.cache[require.resolve('./config.js')]
      config = require('./config').config
      load()
      res.send '<b>Success!</b> Settings Saved.'

app.get '/admin/delete/:id?', users.check, (req, res) ->
  posts.findById req.params.id, (err, docs) ->
    if err
      renderError res, err
    else
      posts.remove docs._id, docs._rev
    res.redirect '/admin'

app.get '/admin/edit/:id?', users.check, (req, res) ->
  posts.findById req.params.id, (err, docs) ->
    if err
      renderError res, err
    else
      res.render admin + 'editor',
        layout: admin + 'layout'
        locals:
          title: 'Edit'
          article: docs

app.post '/admin/new', users.check, (req, res) ->
  slug = sluggify req.param 'title'
  posts.save {
    _id: slug
    title: req.param 'title'
    markdown: ''
    user: req.user.name
    type: 'post'
    status: 'draft'
  }, (err, docs) ->
    if err
      renderError res, err
    else
      res.redirect '/admin'

app.post '/admin/edit', users.check, (req, res) ->
	if (req.param 'slug')
		slug = req.param 'slug'
	else
		slug = sluggify req.param 'title'
	#Tag parsing:
	# Replaces spaces and some special characters with hyphens, so its still a human-
	# readable format that's also url-friendly
	# *note* This is used on the client-side as well, so changes made here must also
	# be made on the client for compatibility.
	# See: editor.js, in the `save` method, check for `//Tag Parsing`
	tags = []
	if (req.param 'tags')
		potentialTag = ''
		tagstr = req.param('tags').split(',')
		for t in tagstr
			potentialTag = t.trim().replace(/[^a-z0-9]+/gi, '-').replace(/^-*|-*$/g, '')
			if (potentialTag != '')
				tags.push potentialTag
	posts.save {
		_id: slug
		title: req.param 'title'
		tags: tags
		markdown: req.param 'body'
		_rev: req.param 'rev'
		user: req.user.name
		type: 'post'
		status: req.param 'status'
	}, (err, docs) ->
		if (err)
			renderError res, err
		else
			res.redirect('/')

app.get '/admin/*', users.check, (req, res) ->
  renderError res, "<b>404:</b> Are you sure that's the right URL?"
      
app.get '/500', (req, res) ->
  res.render front + 'view'
    locals:
      title: config.site.title + ' / 500'
      article:
        title: '500'
        created_at: ''
        body: "Internal Server Error"

app.get '*', (req, res) ->
  res.render front + 'view'
    locals:
      title: config.site.title + ' / 404'
      article:
        title: '404'
        created_at: ''
        body: "Woops! Can't find what you're looking for!"
          
# Other Functions
sluggify = (title) ->
  slug = title.slice(0,30).replace(/\ /ig, '-').toLowerCase()
  
renderError = (res, err) ->
  err = JSON.stringify(err) if typeof err == 'object' 
  res.render admin + 'error'
    layout: admin + 'layout'
    locals:
      title: 'Error'
      error: err
