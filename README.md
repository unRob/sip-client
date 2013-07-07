# A very incomplete SIP Client for Node.js

Given I actually have no idea whether this is a "Client" or a "User-agent" (reading the RFCs drove me a bit mad), take the name with a grain of salt.

## Installation

    npm install sip-client

## Usage

```javascript
var SIPClient = require('/sip-client');
var util = require('util');

// I suppose these are pretty self explanatory
var opts = {
	user: 'myUsername',
	password: 'password',
	host: 'some.sip.host.com',
	debug: false //unless you want to see HARDCORE SIP ACTION!
};

var client = new SIPClient(opts);

var uri = {
	schema: 'sip',
	host: opts.host,
	user: opts.user
};
var headers = {
	contact: "<sip:"+opts.host+":5060>",
	from: {
		name: 'A SIP User',
		uri: uri
	},
	to: {
		name: 'Rob',
		uri: uri
	}
};

var message = client.message('register', {host: opts.host}, headers);
message.send();

message.on('success', function(msg) {
	// You've been authenticated!
	client.on('invite', function(msg){
		// Now call your number, and magic happens
		var from = client.sip.parseUri(msg.headers.from.uri);
		util.log("The most handsome dude(ette), "+from.name+" at "+from.user);
		// outputs "The most handsome dude(ette), Some User at 31415926535"
	});
});

```

## License

As usual, licensed under the [WTFPL](http://www.wtfpl.net).