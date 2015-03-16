//
//  XMLWriter+ConvenienceMethods.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 3/16/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "XMLWriter+ConvenienceMethods.h"

@implementation XMLWriter (ConvenienceMethods)

- (void)writeElement:(NSString *)elementName withContents:(NSString *)contents {
    [self writeElement:elementName withNamespace:nil andContents:contents];
}

- (void)writeElement:(NSString *)elementName
       withNamespace:(NSString *)namespace
         andContents:(NSString *)contents {
    [self writeElement:elementName
         withNamespace:namespace
      andContentsBlock:^(XMLWriter *xmlWriter) {
          [xmlWriter writeCharacters:contents];
      }];
}

- (void)writeElement:(NSString *)elementName
   withContentsBlock:(void (^)(XMLWriter *))writerBlock {
    [self writeElement:elementName
         withNamespace:nil
      andContentsBlock:writerBlock];
}

- (void)writeElement:(NSString *)elementName
       withNamespace:(NSString *)namespace
    andContentsBlock:(void (^)(XMLWriter *))writerBlock {
    NSParameterAssert(writerBlock);

    if (namespace) {
        [self writeStartElementWithNamespace:namespace localName:elementName];
    } else {
        [self writeStartElement:elementName];
    }
    writerBlock(self);
    [self writeEndElement];
}

- (void)writeAttributes:(NSDictionary *)attributes {
    for (NSString *name in attributes) {
        [self writeAttribute:name value:attributes[name]];
    }
}

@end
