//
//  MediaInfo.m
//  Connect SDK
//
//  Created by Jeremy White on 8/14/14.
//  Copyright (c) 2014 LG Electronics.
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

#import "MediaInfo.h"


@implementation MediaInfo
@synthesize description;

// return nil here so that we force users to have URL and mime-type
- (instancetype) init
{
    return nil;
}

- (instancetype) initWithURL:(NSURL *)url mimeType:(NSString *)mimeType
{
    self = [super init];

    if (self)
    {
        self.url = url;
        self.mimeType = mimeType;

        self.images = [NSArray new];
    }

    return self;
}

- (void) addImage:(ImageInfo *)image
{
    self.images = [self.images arrayByAddingObject:image];
}

- (void) addImages:(NSArray *)images
{
    self.images = [self.images arrayByAddingObjectsFromArray:images];
}

@end
