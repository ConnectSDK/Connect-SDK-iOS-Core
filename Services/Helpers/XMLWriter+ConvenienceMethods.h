//
//  XMLWriter+ConvenienceMethods.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 3/16/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "XMLWriter.h"

@interface XMLWriter (ConvenienceMethods)

- (void)writeElement:(NSString *)elementName withContents:(NSString *)contents;

- (void)writeElement:(NSString *)elementName
       withNamespace:(NSString *)namespace
andContents:(NSString *)contents;

- (void)writeElement:(NSString *)elementName
   withContentsBlock:(void (^)(XMLWriter *writer))writerBlock;

- (void)writeElement:(NSString *)elementName
       withNamespace:(NSString *)namespace
andContentsBlock:(void (^)(XMLWriter *writer))writerBlock;

- (void)writeAttributes:(NSDictionary *)attributes;

@end
