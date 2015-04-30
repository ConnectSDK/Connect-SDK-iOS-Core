//
//  CNTConnectError.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 10/4/13.
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

/// The error domain for ConnectSDK errors.
NSString *const CNTConnectErrorDomain;

/*!
 * Helpful status codes that augment the localizedDescriptions of NSErrors that crop up throughout many places of the SDK. Most NSErrors that Connect SDK provides will have a CNTConnectStatusCode.
 */
typedef enum {
    /*! Generic error, unknown cause */
    CNTConnectStatusCodeError = 1000,

    /*! The TV experienced an error */
    CNTConnectStatusCodeTvError = 1001,

    /*! SSL certificate error */
    CNTConnectStatusCodeCertificateError = 1002,

    /*! Error with WebSocket connection */
    CNTConnectStatusCodeSocketError = 1003,

    /*! Requested action is not supported */
    CNTConnectStatusCodeNotSupported = 1100,

    /*! There was a problem with the provided arguments, see error description for details */
    CNTConnectStatusCodeArgumentError = 1101,

    /*! Device is not connected */
    CNTConnectStatusCodeNotConnected = 1102
} CNTConnectStatusCode;

@interface CNTConnectError : NSObject

+ (NSError *) generateErrorWithCode:(CNTConnectStatusCode)code andDetails:(id)details;

@end
