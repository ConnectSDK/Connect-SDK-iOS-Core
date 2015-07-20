//
//  SubtitleTrack.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-14.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SubtitleTrackBuilder;

/**
 * Represents a subtitle track used for media playing.
 *
 * @warning The URL is required, so the @c -init method will throw an exception.
 * Please use the parameterized initializers.
 *
 * @note This class is immutable.
 */
@interface SubtitleTrack : NSObject

/// The subtitle track's URL.
@property (nonatomic, readonly) NSURL *url;

/// The subtitle's mimeType.
@property (nonatomic, readonly, nullable) NSString *mimeType;

/// The subtitle's source language. The contents depend on the target device.
@property (nonatomic, readonly, nullable) NSString *language;

/// A custom label that may be displayed by a device's media player.
@property (nonatomic, readonly, nullable) NSString *label;


/// Creates a new instance with the given @c url.
+ (instancetype)trackWithURL:(NSURL *)url;

/// Creates a new instance with the given @c url and properties set in the
/// @c builder object.
+ (instancetype)trackWithURL:(NSURL *)url
                    andBlock:(void (^)(SubtitleTrackBuilder *builder))block;

@end


/**
 * Used to initialize a @c SubtitleTrack object in a convenient way. The
 * properties are writable at this point, and then become readonly in a final
 * object.
 *
 * @note You should not create this object manually. It is passed as a parameter
 * to <tt>+[SubtitleTrack trackWithURL:andBlock:]</tt> method.
 *
 * @see http://www.annema.me/the-builder-pattern-in-objective-c
 */
@interface SubtitleTrackBuilder : NSObject

/// The subtitle's mimeType.
@property (nonatomic, nullable) NSString *mimeType;

/// The subtitle's source language. The contents depend on the target device.
@property (nonatomic, nullable) NSString *language;

/// A custom label that may be displayed by a device's media player.
@property (nonatomic, nullable) NSString *label;

@end
NS_ASSUME_NONNULL_END
