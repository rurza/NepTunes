//
//  MPISpotifyToken.h
//  NepTunes
//
//  Created by Adam Różyński on 14/10/2017.
//  Copyright © 2017 micropixels. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@interface MPISpotifyToken : JSONModel

@property (nonatomic) NSString          *accessToken;
@property (nonatomic) NSString          *tokenType;
@property (nonatomic) NSNumber          *expiresIn;
@property (nonatomic) NSDate<Ignore>    *expirationDate;

@end
