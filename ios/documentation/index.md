# Ti.TVOut Module

## Description

Adds TV Out functionality to your application, letting you control what is outputted to a TV on iOS devices with the proper adapters.

## Getting Started

View the [Using Titanium Modules](http://docs.appcelerator.com/titanium/latest/#!/guide/Using_Titanium_Modules) document for instructions on getting
started with using this module in your application.

## Accessing the Ti.TVOut Module

To access this module from JavaScript, you would do the following:

<pre>var TVOut = require('ti.tvout');</pre>

## Simulator Notes

When you run in Titanium Developer for the simulator, you'll need to select Hardware..TV Out...

This will cause the simulator to reset. Once the TV out interface is visible, you should start your app from the
simulator directly to test using your app on the TV out simulator view.

## Properties

### Ti.TVOut.connected

Returns true if a screen is connected.

### Ti.TVOut.screen

Returns a dictionary containing information about the connected screen:

* pixelAspectRatio[float]: The ratio of the width to the height.
* scale[float]: How much the screen is being scaled, from the iOS device's native resolution to the television's resolution.
* width[float]: The width of the screen bounds.
* height[float]: The height of the screen bounds.
* size[object]: The size of the current display mode (resolution). Contains two properties: width and height.

## Functions

### start()

Starts outputting to the television. Note that you can listen for the connect and disconnect events to know if output is being sent to a television.

### stop()

Stops outputting to the television.

### setView(view, mirror)

Sets the view that is output to the television.

#### Arguments

* view[object]: The view to output. If the `mirror` argument is `false` then this view will be removed from its parent view
and it is your application's responsibility to update the contents of this view as needed. If the `mirror` argument is `true`
then the contents of the view will be cloned to the television. Set to `null` to reset the television to display the application window.

* mirror[boolean]: Specifies if the `view` is mirrored to the television. Set to `true` to have the contents of the view cloned to
the television. Set to `false` to move the view to the television.

## Events

### connect

Fired when a television screen is connected.

### disconnect

Fired when a television screen is disconnected.

## Usage

See example.

## Author

Jeff Haynie & Jeff English

## Module History

View the [change log](changelog.html) for this module.

## Feedback and Support

Please direct all questions, feedback, and concerns to [info@appcelerator.com](mailto:info@appcelerator.com?subject=Android%20TVOut%20Module).

## License

Copyright(c) 2010-2013 by Appcelerator, Inc. All Rights Reserved. Please see the LICENSE file included in the distribution for further details.
