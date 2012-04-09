exports.config = 

	# Site Information
	site:
		# Site Title - appears in title of pages
		title: 'CouchPress Site'
		# Site Description 
		description: 'Just another CouchPress Site.'
		# Site Copyright Holder
		copyright: 'Joe Bloggs'
		# Twitter Handle - optional
		twitter: 'joebloggs'
		# Site port  - get this from your NodeJS host
		port: ''
		# Session Secret - a random string used to compute the session hash
		secret: 'somestringhere'
		# CouchPress Version
		version: '0.1.2'
	
	# Theme Information
	theme:
		# Folder Name of Admin Theme
		admin: 'admin'
		# Folder Name of Frontend Theme
		front: 'soothe'
		
	# Database Settings - get this info from your CouchDB host
	db:
		# CouchDB Host URL
		host: 'http://www.example.com'
		# CouchDB Host Port
		port: 80
		# CouchDB Admin - create an admin with a password to secure your site
		user: 'admin'
		# CouchDB Admin Password
		pass: ''