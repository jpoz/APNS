# APNS

a gem for the Apple Push Notification Service.

## Install

sudo gem install apns

## Setup

Convert your certificate

In Keychain access export your certificate as a p12. Then run the following
command to convert it to a .pem

``` bash
openssl pkcs12 -in cert.p12 -out cert.pem -nodes -clcerts
```

After you have your .pem file. Set what host, port, certificate file location
on the APNS class:

``` ruby
APNS.host = 'gateway.push.apple.com'
# gateway.sandbox.push.apple.com is default

APNS.pem  = '/path/to/pem/file'
# this is the file you just created

APNS.port = 2195
# this is also the default. Shouldn't ever have to set this, but just in case
# Apple goes crazy, you can.
```

## Example (Single notification):

Then to send a push notification you can either just send a string as the
alert or give it a hash for the alert, badge and sound.

``` ruby
device_token = '123abc456def'

APNS.send_notification(device_token, 'Hello iPhone!' )
APNS.send_notification(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default')
```

## Example (Multiple notifications):

You can also send multiple notifications using the same connection to Apple:

``` ruby
device_token = '123abc456def'

n1 = APNS::Notification.new(device_token, 'Hello iPhone!' )
n2 = APNS::Notification.new(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default')

APNS.send_notifications([n1, n2])
```

## Send other info along with aps

You can send other application specific information as well.

``` ruby
APNS.send_notification(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default',
																		 :other => {:sent => 'with apns gem'})
```

This will add the other hash to the same level as the aps hash:

``` json
{"aps":{"alert":"Hello iPhone!","badge":1,"sound":"default"},"sent":"with apns gem"}
```


## Getting your iPhone's device token

After you setup push notification for your application with Apple. You need to ask Apple for you application specific device token.

``` objc
- (void)applicationDidFinishLaunching:(UIApplication *)application {
		// Register with apple that this app will use push notification
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | 
			UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge)];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
		// Show the device token obtained from apple to the log
		NSLog(@"deviceToken: %@", deviceToken);
}
```

## Creating a second client

Sometimes it can be useful to have a second (or third!) client to work with to manage multiple credential sets.

``` ruby
client = APNS::Client.new
client.send_notification(device_token, :alert => 'hello!')
```
