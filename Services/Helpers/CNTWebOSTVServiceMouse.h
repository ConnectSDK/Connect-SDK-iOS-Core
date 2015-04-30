//
//  CNTWebOSTVServiceMouse.h
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

typedef enum {
    CNTWebOSTVMouseButtonHome = 1000,
    CNTWebOSTVMouseButtonBack = 1001,
    CNTWebOSTVMouseButtonUp = 1002,
    CNTWebOSTVMouseButtonDown = 1003,
    CNTWebOSTVMouseButtonLeft = 1004,
    CNTWebOSTVMouseButtonRight = 1005
} CNTWebOSTVMouseButton;

@interface CNTWebOSTVServiceMouse : NSObject

- (instancetype) initWithSocket:(NSString*)socket success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) move:(CGVector)distance;
- (void) scroll:(CGVector)distance;
- (void) click;
- (void) button:(CNTWebOSTVMouseButton)keyName;
- (void) disconnect;

@end
