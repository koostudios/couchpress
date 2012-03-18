(function() {
  var Articler, app, article, exp;

  exp = require('express');

  app = exp.createServer();

  Articler = require('./articler').Articler;

  article = new Articler('http://localhost', 5984);

  app.configure(function() {
    app.set('view engine', 'jade');
    app.set('views', __dirname + '/views');
    app.use(exp.static(__dirname + '/public'));
    app.use(exp.bodyParser());
    return app.use(exp.methodOverride());
  });

  app.listen(1337);

  console.log('Server running at http://localhost:1337/');

  app.get('/', function(req, res) {
    return article.findAll(function(err, docs) {
      return res.render('index', {
        locals: {
          title: 'CouchPress',
          articles: docs
        }
      });
    });
  });

  app.get('/new', function(req, res) {
    return res.render('new', {
      locals: {
        title: 'CouchPress / New Post'
      }
    });
  });

  app.post('/new', function(req, res) {
    return article.save({
      title: req.param('title'),
      body: req.param('body'),
      created_at: new Date()
    }, function(err, docs) {
      return res.redirect('/');
    });
  });

}).call(this);
