//
//  CNTKeyControl.h
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

#define kCNTKeyControlAny @"CNTKeyControl.Any"

#define kCNTKeyControlUp @"CNTKeyControl.Up"
#define kCNTKeyControlDown @"CNTKeyControl.Down"
#define kCNTKeyControlLeft @"CNTKeyControl.Left"
#define kCNTKeyControlRight @"CNTKeyControl.Right"
#define kCNTKeyControlOK @"CNTKeyControl.OK"
#define kCNTKeyControlBack @"CNTKeyControl.Back"
#define kCNTKeyControlHome @"CNTKeyControl.Home"
#define kCNTKeyControlSendKeyCode @"CNTKeyControl.Send.KeyCode"

#define kCNTKeyControlCapabilities @[\
    kCNTKeyControlUp,\
    kCNTKeyControlDown,\
    kCNTKeyControlLeft,\
    kCNTKeyControlRight,\
    kCNTKeyControlOK,\
    kCNTKeyControlBack,\
    kCNTKeyControlHome,\
    kCNTKeyControlSendKeyCode\
]

@protocol CNTKeyControl <NSObject>

- (id<CNTKeyControl>) keyControl;
- (CNTCapabilityPriorityLevel) keyControlPriority;

- (void) upWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) downWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) leftWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) rightWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) okWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) backWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) homeWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) sendKeyCode:(NSUInteger)keyCode success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

@end
