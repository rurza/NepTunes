//
//  SavedSong.h
//  NepTunes
//
//  Created by rurza on 20/01/16.
//  Copyright © 2016 micropixels. All rights reserved.
//

#import "Song.h"

@interface SavedSong : Song <NSCoding>

@property (nonatomic) NSDate *date;

-(instancetype)initWithSong:(Song *)song andDate:(NSDate *)date;

@end
