net = require 'net'
sip = require 'sip'
digest = require 'sip/digest'
proxy = require 'sip/proxy'
util = require 'util'
_ = require 'underscore'

Client = (options)->
	@options = _.defaults(options, Client.defaultOptions)
	@socket = net.connect({port: @options.port, host: @options.host})
	@sipSocket = sip.start({port:31337})
	@socket.setTimeout(10000)
	@socket.on 'data', (d)=>
		@receive(d)
	@messages = {}
	@events = {}
	@sip = sip;
	#@socket.setNoDelay(true)
	return this

Client.defaultOptions =
	debug: false
	port: 5060

Client.uuid = ()->
	f = ()->
		return Math.floor((1+Math.random())*0x100000).toString(16)
	
	[f(),f(),f(),f()].join('-')

Client.log = (msg, out=true)->
	char = if out==true then '>' else '<'
	char += ' '
	msg = msg.split("\n").map((line)->
		return char+line
	).join("\n")
	console.log(msg)

Client.prototype.send = (string)->
	@options.debug && Client.log(string)
	@socket.write string

Client.prototype.on = (evt, callback)->
	evt = evt.toLowerCase()
	@events[evt] = @events[evt] || []
	@events[evt].push(callback)

Client.prototype.receive = (data)->
	msg = sip.parse(data.toString())
	@options.debug && Client.log(data.toString(), false)
	status = msg.status
	
	if status == 100
		return
	
	request = @messages[msg.headers['call-id']]
	
	switch status
		when undefined
			method = msg.method.toLowerCase()
			@events[method] && @events[method].forEach (cb)->
				cb(msg)
		when 200
			request.events.success.forEach (cb)->
				cb(msg)
		when 407
			challenge = msg.headers['proxy-authenticate'][0]
			challenge.realm = challenge.realm.replace(/"/g, '')
			request.inc_cseq()
			response = digest.signRequest([challenge], request, msg, {user: @options.user, realm: challenge.realm, password:@options.password})
			@send (sip.stringify(response))



Client.prototype.message = (method, uri, headers, body='')->
	m = new Message(method, uri, headers, body, @options.host, @options.user)
	m.client = this;
	@messages[m.callid] = m
	
Message = (method, uri, headers, body, host, user)->
	@seq = 1;
	@callid = Client.uuid()
	@events = {
		'success': []
		'fail': []
	}
	@method = method.toUpperCase()
	if typeof uri == 'string'
		parts = uri.split('@')
		if parts.length == 1
			host = uri
		else
		uri =
			schema: schema || 'sip'
			user: user
			host: host
	
	uri.schema = uri.schema || 'sip'
	uri.host = host || host
	@uri = uri
	defaultHeaders = {
		'call-id': @callid
		from: 
			name: 'SipUser'
			uri:
				schema: uri.schema
				host: host
				user: user
		via: [
			version: '2.0'
			protocol: 'tcp'
			host: uri.host
		]
		cseq: {seq: 1, method: @method}
	}
	@headers = _.defaults(headers, defaultHeaders)
	return this

Message.prototype.inc_cseq= ()->
	@headers.cseq.seq += 1

Message.prototype.send = ()->
	@client.send(@toString())
	return this
	
Message.prototype.on = (event, callback)->
	@events[event].push callback

Message.prototype.sip = ()->
	return {
		method: @method
		uri: @uri
		headers: @headers
	}

Message.prototype.toString = ()->
	return sip.stringify(@sip())
	
module.exports = Client