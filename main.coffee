# Requires and Variables
exp = require 'express'
app = exp.createServer()
pass = require 'passport'
Local = require('passport-local').Strategy
fs = require 'fs'
config = require('./config').config

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
 
# Run App
app.listen config.site.port, () ->
  console.log 'Server running at port ' + app.address().port

# Routing
app.get '/', (req, res) ->
  posts.findAll (err, docs) ->
        res.render front + 'index',
            locals:
              title: config.site.title + ' / Home'
              articles: docs
              config: config

app.get '/:id?', (req, res, next) ->
  posts.findById req.params.id, (err, docs) ->
    if err
      next()
    else if docs.status != 'draft'
      res.render front + 'view',
        locals:
          title: config.site.title + ' / ' + docs.title
          article: docs
          config: config
    else
      next()

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
          title: config.site.title
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
	console.log(req.body)
	console.log(req.files)

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
			console.warn("ERROR UPLOADING: ", err)
		else
			res.redirect('/admin/uploads')

app.get '/admin/settings', users.check, (req, res) ->
  adminConfig = require('./config').admin
  res.render admin + 'settings',
    layout: admin + 'layout'
    locals:
      title: 'Settings'
      config: config
      admin: adminConfig

app.post '/admin/settings', users.check, (req, res) ->
  Data = JSON.stringify JSON.parse(req.param('data')), null, 2
  Admin = JSON.stringify JSON.parse(req.param('admin')), null, 2
  template = 'exports.config = ' +  Data + ';\nexports.admin = ' + Admin
  fs.writeFile './config.js', template, 'utf8', (err) ->
    if err
      res.send '<b>Error:</b>' + err
    else
      res.send '<b>Success!</b> Settings Saved.'
      delete require.cache[require.resolve('./config')]
      config = require('./config').config

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
          config: config

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
  posts.save {
    _id: slug
    title: req.param 'title'
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
      
app.get '*', (req, res) ->
  res.render front + 'view'
    locals:
      title: config.site.title + ' / 404'
      article:
        title: '404'
        created_at: ''
        body: "Woops! Can't find what you're looking for!"
      config: config
          
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
