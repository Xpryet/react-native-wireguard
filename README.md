
# react-native-wireguard

## Getting started

`$ npm install react-native-wireguard --save`

### Mostly automatic installation

`$ react-native link react-native-wireguard`

### Extra steps

#### iOS

Doesn't work on iOS yet. SOON...

#### Android

1. Insert the following service lines to your `AndroidManifest.xml`:
    ```xml
    <application>

        ....

        <service
            android:name="com.wirevpn.rnwireguard.WGVpnService"
            android:permission="android.permission.BIND_VPN_SERVICE">
            <intent-filter>
                <action android:name="android.net.VpnService" />
            </intent-filter>
        </service>

        ....

    </application>
  	```
2. Insert your notification area icon(s) to `res/drawable` or to its multiple hidpi counterparts.
3. Insert your `applicationId` to the top level `build.gradle` to have it accessible.
    ```
    buildscript {

        ....

        ext {
            minSdkVersion = 21
            targetSdkVersion = 26
            compileSdkVersion = 28

            ....

            applicationId = "com.wirevpn.android"
        }

        ....
    }
    ```


## Usage
```javascript
import WireGuard from 'react-native-wireguard';

// Gets the version of the underying wireguard-go
WireGuard.Version().then((v) => this.setState{version: v});

// Config is of type wg-quick
// MTU is optional and defaults to 1420
// If endpoint resolves to multiple IP addresses,
// IPv4 is preferred over IPv6
var config = `
    [Interface]
    PrivateKey = mBEJJwnMh6Ht9xLp88nTtHqmOY9pnN7YdriotquvgVI=
    Address = 192.168.7.237/32, fdaa::7f3/128
    DNS = 192.168.0.0, fdaa::

    [Peer]
    PublicKey = Cf0rdfToO5gxg7ObB6dLbTwfElO3Xx7Fh8jJobmqCnE=
    AllowedIPs = 0.0.0.0/0, ::/0
    Endpoint = 209.97.177.222:51820`;

// A name for your session
var session = 'MyVPNSession';

// After a successfull connection, application is brought to
// foreground and needs a notification
var notif = {
    icon: 'ic_notif_icon', // Name of the icon in /res directory
    title: 'My VPN',
    text: 'Connected to ' + country;
}

// Starts the VPN connection
// After successfull connection you will receive an event
WireGuard.Connect(config, session, notif).catch(
    (e) => console.warn(e.message));

// Check if VPN service is online
WireGuard.Status().then((b) => {
    if(b){
        // Update state
    }
});

// Terminates the connection
// After successfull termination of the connection you will
// receive an event
WireGuard.Disconnect()

componentDidMount() {
    DeviceEventEmitter.addListener(WireGuard.EV_TYPE_SYSTEM, () => {
		if(e === WireGuard.EV_STARTED_BY_SYSTEM) {
			// This event is emitted when VPN service is started
            // by the system. For example if a user enables Always-On
            // in settings, system will try to bring the VPN online but
            // since it doesn't have any config it will fail and send
            // this event instead so that you can start it correctly
            // here...
		}
    });

    // If any exceptions occur after calling the Connect()
    // method you can catch them here. e is of type string
    DeviceEventEmitter.addListener(WireGuard.EV_TYPE_EXCEPTION, () => {
		console.log(e);
    });

    DeviceEventEmitter.addListener(WireGuard.EV_TYPE_REGULAR, () => {
        if(e === WireGuard.EV_STOPPED) {
            // Update state
		} else if(e === WireGuard.EV_STARTED) {
			// Update state
		}
    });
}

componentWillUnmount() {
    // You will receive the same event multiple times
    // if this not set
    DeviceEventEmitter.removeAllListeners();
}

```# react-native-wireguard
