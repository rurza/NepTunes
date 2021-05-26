//
//  PluginsInterface.h
//  Plugins
//
//  Created by Adam Różyński on 26/05/2021.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PluginsInterface <NSObject>

- (void)trackDidChange:(NSString *)title byArtist:(NSString *)artist;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
