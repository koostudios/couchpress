# Requires and Variables
exp = require 'express'
app = exp.createServer()

# Articler Class - Remember to Change to Iris Couch
Articler = require('./articler').Articler
article = new Articler 'http://couchpress.iriscouch.com', 80
 
# App Configuration
app.configure () ->
    app.set 'view engine', 'jade'
    app.set 'views', __dirname + '/views'
    app.use exp.static __dirname + '/public'
    app.use exp.bodyParser()
    app.use exp.methodOverride()
 
# Run App
app.listen 16488
console.log 'Server running at port 16488'

# Routing
app.get '/', (req, res) ->
	article.findAll (err, docs) ->
        res.render 'index',
            locals:
                title: 'CouchPress'
                articles: docs

app.get '/view/:id', (req, res) ->
	article.findById req.params.id, (err, docs) ->
		res.render 'view',
			locals:
				title: 'Couchpress /' + docs.title
				article: docs

app.get '/admin', (req, res) ->
	article.findAll (err, docs) ->
		res.render 'admin/posts',
			layout: 'admin/layout'
			locals:
				title: 'Posts'
				articles: docs

app.get '/admin/new', (req, res) ->
    res.render 'admin/new',
    	layout: 'admin/layout',
    	locals:
    		title: 'New'

app.get '/admin/edit/:id', (req, res) ->
	article.findById req.params.id, (err, docs) ->
		res.render 'admin/new'
			layout: 'admin/layout'
			locals:
				title: 'Edit'
				article: docs

app.post '/admin/new', (req, res) ->
	docs = 
		title: req.param 'title'
		body: ''
	res.render 'admin/new'
		layout: 'admin/layout',
		locals:
			title: 'New'
			article: docs

app.post '/admin/edit', (req, res) ->
    if (req.param 'slug')
        slug = req.param 'slug'
    else
        slug = sluggify req.param 'title'
    article.save {
        _id: slug
        title: req.param 'title'
        body: req.param 'body'
        _rev: req.param 'rev'
        created_at: new Date()
    }, (err, docs) ->
    	if (err)
    		res.render 'admin/error'
    			layout: 'admin/layout'
    			locals:
    				title: 'Error'
    				error: JSON.stringify(err)
    	else
        	res.redirect('/')
        	
# Other Functions
sluggify = (title) ->
	slug = title.slice(0,30).replace(/\ /ig, '-').toLowerCase()