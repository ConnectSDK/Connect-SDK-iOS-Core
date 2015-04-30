//
//  CNTProgramInfo.h
//  Connect SDK
//
//  Created by Jeremy White on 1/19/14.
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

@class CNTChannelInfo;


/*! Normalized reference object for information about a TVs program. */
@interface CNTProgramInfo : NSObject

/*! ID of the program on the first screen device. Format is different depending on the platform. */
@property (nonatomic, strong) NSString *id;

/*! User-friendly name of the program (ex. Sesame Street, Cosmos, Game of Thrones, etc). */
@property (nonatomic, strong) NSString *name;

/*! Reference to the CNTChannelInfo object that this program is associated with */
@property (nonatomic, strong) CNTChannelInfo *channelInfo;

/*! Raw data from the first screen device about the program. In most cases, this is an NSDictionary. */
@property (nonatomic, strong) id rawData;

/*!
 * Compares two CNTProgramInfo objects.
 *
 * @param programInfo CNTProgramInfo object to compare.
 *
 * @return YES if both CNTProgramInfo id & name values are equal
 */
- (BOOL)isEqual:(CNTProgramInfo *)programInfo;

@end
