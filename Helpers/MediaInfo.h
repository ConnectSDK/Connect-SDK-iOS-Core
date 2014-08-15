//
//  MediaInfo.h
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

#import <Foundation/Foundation.h>
#import "ImageInfo.h"


@interface MediaInfo : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic, strong) NSArray *images;

- (instancetype) initWithURL:(NSURL *)url mimeType:(NSString *)mimeType;

- (void) addImage:(ImageInfo *)image;
- (void) addImages:(NSArray *)images;

@end
