//
//  CNTToastControl.h
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
#import "CNTCapability.h"
#import "CNTAppInfo.h"

#define kCNTToastControlAny @"CNTToastControl.Any"

#define kCNTToastControlShowToast @"CNTToastControl.Show"
#define kCNTToastControlShowClickableToastApp @"CNTToastControl.Show.Clickable.App"
#define kCNTToastControlShowClickableToastAppParams @"CNTToastControl.Show.Clickable.App.Params"
#define kCNTToastControlShowClickableToastURL @"CNTToastControl.Show.Clickable.URL"

#define kCNTToastControlCapabilities @[\
    kCNTToastControlShowToast,\
    kCNTToastControlShowClickableToastApp,\
    kCNTToastControlShowClickableToastAppParams,\
    kCNTToastControlShowClickableToastURL\
]

@protocol CNTToastControl <NSObject>

- (id<CNTToastControl>)toastControl;
- (CNTCapabilityPriorityLevel)toastControlPriority;

- (void) showToast:(NSString *)message success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) showToast:(NSString *)message iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) showClickableToast:(NSString *)message appInfo:(CNTAppInfo *)appInfo params:(NSDictionary *)params success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) showClickableToast:(NSString *)message appInfo:(CNTAppInfo *)appInfo params:(NSDictionary *)params iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) showClickableToast:(NSString *)message URL:(NSURL *)URL success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) showClickableToast:(NSString *)message URL:(NSURL *)URL iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

@end
