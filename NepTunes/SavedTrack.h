//
//  SavedSong.h
//  NepTunes
//
//  Created by rurza on 20/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "Track.h"

@interface SavedTrack : Track <NSCoding>

@property (nonatomic) NSDate *date;

-(instancetype)initWithTrack:(Track *)song andDate:(NSDate *)date;

@end
