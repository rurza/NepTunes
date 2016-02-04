# iTunesSearch - block based iTunes store communication for iOS and Mac OS X

[![Badge w/ Version](https://cocoapod-badges.herokuapp.com/v/iTunesSearch/badge.png)](http://cocoadocs.org/docsets/iTunesSearch)
[![Badge w/ Platform](https://cocoapod-badges.herokuapp.com/p/iTunesSearch/badge.svg)](http://cocoadocs.org/docsets/iTunesSearch)

A library for communicating with the iTunes store.

### Features
- Get albums for artists
- Get tracks for album
- Get apps by developer
- Search podcasts

And:
- Block based for easier usage
- No dependencies
- Result caching

## Usage
```objective-c
// Set the PHG Affiliate Token info
[ItunesSearch sharedInstance].affiliateToken = @"xxx";

// Get artist info
[[ItunesSearch sharedInstance] getAlbumsForArtist:@"Pink Floyd" limitOrNil:@20 successHandler:^(NSArray *result) {
    NSLog(@"result: %@", result);
} failureHandler:^(NSError *error) {
    NSLog(@"error: %@", error);
}];
```


## Installation
You can install iTunesSearch with [CocoaPods](http://cocoapods.org). You can also get the code and drag the iTunesSearch subfolder into your Xcode project.

### Requirements
* iTunesSearch is built using ARC and modern Objective-C syntax. You will need Xcode 4.4 or higher to use it in your project.
* iTunesSearch uses NSJSONSerialization and thus needs iOS 5 or higher.


## Issues and questions
Have a bug? Please [create an issue on GitHub](https://github.com/gangverk/iTunesSearch/issues)!


## Contributing
iTunesSearch is an open source project and your contribution is very much appreciated.

1. Check for [open issues](https://github.com/gangverk/iTunesSearch/issues) or [open a fresh issue](https://github.com/gangverk/iTunesSearch/issues/new) to start a discussion around a feature idea or a bug.
2. Fork the [repository on Github](https://github.com/gangverk/iTunesSearch) and make your changes on the **develop** branch (or branch off of it).
3. Make sure to add yourself to AUTHORS and send a pull request.


## Apps using iTunesSearch
* Last.fm Scrobbler

Are you using iTunesSearch in your iOS or Mac OS X app? Send a pull request with an updated README.md file to be included.


## License
iTunesSearch is available under the MIT license. See the LICENSE file for more info.
