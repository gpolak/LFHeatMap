Mapbox iOS SDK
--------------

Based on the Route-Me iOS map library (Alpstein fork) with [Mapbox](http://mapbox.com) customizations. 

Requires iOS 5 or greater (includes iOS 7+ support at runtime), Xcode 5.0 or greater, and ARC.

[![](https://raw.github.com/mapbox/mapbox-ios-sdk/packaging/screenshot.png)]()

Major differences from [Alpstein fork of Route-Me](https://github.com/Alpstein/route-me): 

 * Requires iOS 5.0 and above. 
 * Supports Automatic Reference Counting (ARC). 
 * [Mapbox](http://mapbox.com) & [MBTiles](http://mbtiles.org) tile source integration code. 
 * [Mapbox Markers](http://mapbox.com/blog/markers/) support. 
 * [UTFGrid interactivity](http://mapbox.com/mbtiles-spec/utfgrid/). 
 * Improved network tile loading performance. 
 * A bulk, background map tile downloader for cache pre-population and offline use. 
 * Annotation callouts that behave like MapKit. 
 * Annotation convenience subclasses for points and shapes. 
 * Prepackaged static library. 
 * [CocoaPods](http://cocoapods.org) support. 
 * Removal of two-finger double-tap gesture for zoom out (to speed up two-finger single-tap recognition like MapKit). 
 * Different default starting location for maps. 
 * Built-in attribution view controller with button on map views & default OpenStreetMap attribution. 
 * Easy static map view support. 
 * Removal of included example projects in favor of separate examples on GitHub. 
 * A few added defaults for convenience. 
 * Improved documentation. 

Keep your eye also on [Mapbox GL](https://www.mapbox.com/blog/mapbox-gl/), the future of our rendering technology. We are aiming to have a clear upgrade path between existing toolsets and GL as it matures. Read more in the [Mapbox GL Cocoa FAQ](https://github.com/mapbox/mapbox-gl-cocoa/blob/master/FAQ.md). 

Route-Me
--------

Route-Me is an open source map library that runs natively on iOS.  It's designed to look and feel much like the built-in iOS map library, but it's entirely open, and works with any map source using a pluggable backend system. 

Supported map tile sources include [Mapbox](http://mapbox.com/developers/api/)/[TileStream](https://github.com/mapbox/tilestream), the offline-capable, database-backed format [MBTiles](http://mbtiles.org), [OpenStreetMap](http://www.openstreetmap.org), and several others. 

Please note that you are responsible for getting permission to use the map data, and for ensuring your use adheres to the relevant terms of use.

Installation
------------

There are three ways that you can install the SDK, depending upon your needs: 

 1. Clone from GitHub and integrate as a dependent Xcode project. 
 1. Use the [static library](http://mapbox-ios-sdk.s3.amazonaws.com/index.html). Link it in your project, add `#import <Mapbox/Mapbox.h>`, and additionally, include the `-ObjC` linker flag. 
 1. Install via [CocoaPods](http://cocoapods.org). 

More detailed information on the installation options is available in the [SDK guide](http://mapbox.com/mapbox-ios-sdk/). 

The two main branches of the GitHub repository are pretty self-explanatory: `release` and `develop`. When we tag a [release](https://github.com/mapbox/mapbox-ios-sdk/tags), we also merge `develop` over to `release`, except in the case of minor point releases (e.g., `0.4.2`), where we might just bring over a fix or two from `develop`. 

Then, update the submodules:

      git submodule update --init

Some example apps showing usage of the SDK (with screenshots):

 * [Mapbox iOS Example](https://github.com/mapbox/mapbox-ios-example) - online, offline, and interactive tile sources
 * [Mapbox Me](https://github.com/mapbox/mapbox-me) - user location services and terrain toggling
 * [Weekend Picks](https://github.com/mapbox/weekend-picks-template-ios) - markers and data

More documentation is available: 

      http://mapbox.com/mapbox-ios-sdk/

There are two subdirectories - MapView and Proj4. Proj4 is a support library used to do map projections. The MapView project contains only the Route-Me map library. 

See License.txt for license details. In any app that uses this SDK, include the following text on your "preferences" or "about" screen: "Uses Mapbox iOS SDK, (c) 2008-2014 Mapbox and Route-Me Contributors". Your data provider will have additional attribution requirements.

News, Support and Contributing
------------------------------

Complete API documentation is available [online](http://mapbox.com/mapbox-ios-sdk/api/) or as an [Xcode docset Atom feed](http://mapbox.com/mapbox-ios-sdk/Docs/publish/docset.atom). 

The Mapbox iOS SDK has a [support resource](http://support.mapbox.com/discussions/mapbox-ios-sdk) where you can open cases and browse other developers' discussions about use of the SDK. 

We have a [basic technical overview](http://mapbox.com/mapbox-ios-sdk/) along with the installation instructions. 

Mapbox has an IRC channel on `irc.freenode.net` in `#mapbox`. 

To report bugs and help fix them, please use the [issue tracker](https://github.com/mapbox/mapbox-ios-sdk/issues). 

Dependent Libraries
-------------------

The Mapbox iOS SDK makes use of several sub-libraries, listed below. See License.txt for more detailed information about Route-Me and Proj4 and see the individual license files in the sub-libraries for more information on each. 

 * [FMDB](https://github.com/ccgus/fmdb) by Gus Mueller (SQLite for caching and MBTiles)
 * [GRMustache](https://github.com/groue/GRMustache) by Gwendal Roué (Mustache templates)
 * [SMCalloutView](https://github.com/nfarina/calloutview) by Nick Farina (annotation callouts)
