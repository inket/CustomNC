## CustomNC

<img src="http://i.imgur.com/TEbshov.png" align="center" height="676" width="542" >

**Original description**

When Mountain Lion came out and I had to switch to Notification Centre from Growl (in an effort to reduce redundancy), I kind of missed the control I had over how notifications are displayed. Especially banners, which seemed to stay on screen for an unnecessary long time.

So I came up with this.

Essentially, it's an app to personalise your Notification Centre banners and alerts. It's risk-free, easy to setup and uninstalls with a single click.

What it does behind the scenes is:

- Install a SIMBL plugin and gives it your parameters

**Mavericks update**

Apple changed LOTS of things in Notification Center with Mavericks. As you can see in CustomNC.m, the only thing that didn't require a rewrite is the bit relating to Growl. It's why this update took so much time.

Please note that the icon pulse and the Poof exit animation options were removed/disabled from Notification Center and can't be selected in CustomNC anymore. On the upper hand, they gave us a new exit animation, "Raise", which is pretty cool.

**Yosemite update**

Apple didn't change much so updating the app was pretty easy and straightforward but this time around they took away the "Raise" animation and put back "Poof". Why can't we have both ?

**El Capitan update**

Notification Center didn't change that much so this update is more about supporting new locations for SIMBL.

#### Requirements

- SIMBL (install easily with [mySIMBL](https://github.com/w0lfschild/mySIMBL))

#### Download

[Download here!](https://github.com/inket/CustomNC/releases)

#### Changelog

###### 1.5
- Dropped EasySIMBL support.
- Dropped support for Mavericks and older.
- Added support for El Capitan & Yosemite 10.10.4+
- Codesigned.

###### 1.4
- Added support for Yosemite.

###### 1.3
- Added support for Mavericks.
- Settings are now applied instantly instead of re-injecting the plug-in each time.

###### 1.2
- Growl: network notifications will have Growl's icon instead of a random app icon
- Fixed *Notify* button not working in some cases
- Sharing on Github!

###### 1.1.1
- Added EasySIMBL support & ability to test Growl notifications

###### 1.1
- Now with Growl enhancements!

#### License
This program is licensed under GNU GPL v3.0 (see LICENSE)
