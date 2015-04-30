//
//  CNTConnectError.m
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

#import "CNTConnectError.h"

NSString *const CNTConnectErrorDomain = @"com.lge.connectsdk.error";

@implementation CNTConnectError

+ (NSError *) generateErrorWithCode:(CNTConnectStatusCode)code andDetails:(id)details
{
    NSString *errorMessage;
    
    switch (code)
    {
        case CNTConnectStatusCodeTvError:
            errorMessage = [NSString stringWithFormat:@"API error: %@", details];
            break;
            
        case CNTConnectStatusCodeCertificateError:
            errorMessage = [NSString stringWithFormat:@"Invalid server certificate"];
            break;
            
        case CNTConnectStatusCodeSocketError:
            errorMessage = [NSString stringWithFormat:@"Web Socket Error: %@", details];
            break;
            
        case CNTConnectStatusCodeNotSupported:
            errorMessage = [NSString stringWithFormat:@"This feature is not supported."];
            break;
        
        default:
            if (details)
                errorMessage = [NSString stringWithFormat:@"A generic error occured: %@", details];
            else
                errorMessage = [NSString stringWithFormat:@"A generic error occured"];
    }
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:CNTConnectErrorDomain code:code userInfo:userInfo];

}

@end
