//
//  SubtitleTrack.m
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

#import "SubtitleTrack.h"

NS_ASSUME_NONNULL_BEGIN
@implementation SubtitleTrack

#pragma mark - Init

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Please use parameterized initializers to create an instance"
                                 userInfo:nil];
}

+ (instancetype)trackWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url];
}

+ (instancetype)trackWithURL:(NSURL *)url
                    andBlock:(void (^)(SubtitleTrackBuilder *))block {
    SubtitleTrackBuilder *builder = [SubtitleTrackBuilder new];
    block(builder);
    return [[self alloc] initWithURL:url andBuilder:builder];
}

#pragma mark - Private Init

- ( instancetype)initWithURL:(NSURL *)url {
    return [self initWithURL:url andBuilder:nil];
}

- (instancetype)initWithURL:(NSURL *)url
                 andBuilder:(nullable SubtitleTrackBuilder *)builder /*NS_DESIGNATED_INITIALIZER*/ {
    self = [super init];

    _url = url;
    _mimeType = builder.mimeType;
    _language = builder.language;
    _label = builder.label;

    return self;
}

@end


@implementation SubtitleTrackBuilder

@end
NS_ASSUME_NONNULL_END
