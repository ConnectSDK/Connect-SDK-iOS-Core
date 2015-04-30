//
//  CNTMouseControl.h
//  Connect SDK
//
//  Created by Jeremy White on 1/3/14.
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
#import "CNTCapability.h"

#define kCNTMouseControlAny @"CNTMouseControl.Any"

#define kCNTMouseControlConnect @"CNTMouseControl.Connect"
#define kCNTMouseControlDisconnect @"CNTMouseControl.Disconnect"
#define kCNTMouseControlClick @"CNTMouseControl.Click"
#define kCNTMouseControlMove @"CNTMouseControl.Move"
#define kCNTMouseControlScroll @"CNTMouseControl.Scroll"

#define kCNTMouseControlCapabilities @[\
    kCNTMouseControlConnect,\
    kCNTMouseControlDisconnect,\
    kCNTMouseControlClick,\
    kCNTMouseControlMove,\
    kCNTMouseControlScroll\
]

@protocol CNTMouseControl <NSObject>

- (id<CNTMouseControl>)mouseControl;
- (CNTCapabilityPriorityLevel)mouseControlPriority;

- (void) connectMouseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) disconnectMouse;

- (void) clickWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) move:(CGVector)distance success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) scroll:(CGVector)distance success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

@end
