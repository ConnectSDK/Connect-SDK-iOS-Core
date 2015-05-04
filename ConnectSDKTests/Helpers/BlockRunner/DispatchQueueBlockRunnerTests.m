//
//  DispatchQueueBlockRunnerTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/4/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
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

#import "DispatchQueueBlockRunner.h"

@interface DispatchQueueBlockRunnerTests : XCTestCase

@property (strong) DispatchQueueBlockRunner *runner;
@property (strong) dispatch_queue_t queue;

@end

@implementation DispatchQueueBlockRunnerTests

- (void)setUp {
    [super setUp];

    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.runner = [[DispatchQueueBlockRunner alloc] initWithDispatchQueue:self.queue];
}

- (void)tearDown {
    self.queue = nil;
    self.runner = nil;

    [super tearDown];
}

- (void)testClassShouldImplementBlockRunner {
    XCTAssertTrue([self.runner.class conformsToProtocol:@protocol(BlockRunner)]);
}

- (void)testNilQueueInInitShouldNotBeAccepted {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([[DispatchQueueBlockRunner alloc] initWithDispatchQueue:nil],
                    @"nil queue is not accepted");
#pragma clang diagnostic pop
}

- (void)testDefaultInitShouldNotBeAllowed {
    XCTAssertThrows([DispatchQueueBlockRunner new], @"queue must be specified");
}

- (void)testNilBlockShouldNotBeAccepted {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([self.runner runBlock:nil], @"nil block is not accepted");
#pragma clang diagnostic pop
}

- (void)testBlockShouldNotBeRunSynchronously {
    __block NSUInteger testValue = 0;
    void(^incrementValueBlock)(void) = ^{
        ++testValue;
    };
    [self.runner runBlock:incrementValueBlock];
    XCTAssertEqual(testValue, 0,
                   @"The block should not run synchronously");
}

- (void)testBlockShouldBeRunAsynchronously {
    __block NSUInteger testValue = 0;
    void(^incrementValueBlock)(void) = ^{
        ++testValue;
    };

    XCTestExpectation *allBlockAreRun = [self expectationWithDescription:
                                         @"All blocks on the queue are run"];
    // NB: since dispatch_get_current_queue() is deprecated, we have to make
    // assumptions with workarounds
    dispatch_async(self.queue, ^{
        XCTAssertEqual(testValue, 0, @"The block should not have been run yet");
    });
    [self.runner runBlock:incrementValueBlock];
    dispatch_async(self.queue, ^{
        [allBlockAreRun fulfill];
    });

    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];
    XCTAssertEqual(testValue, 1, @"The block should have been run already");
}

- (void)testInstancesShouldBeEqualIfQueuesAreEqual {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    DispatchQueueBlockRunner *runner = [[DispatchQueueBlockRunner alloc]
                                        initWithDispatchQueue:queue];
    XCTAssertEqualObjects(self.runner, runner,
                          @"The two instances should be equal because they use the same queue");
}

- (void)testHashesShouldBeEqualIfQueuesAreEqual {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    DispatchQueueBlockRunner *runner = [[DispatchQueueBlockRunner alloc]
                                        initWithDispatchQueue:queue];
    XCTAssertEqual(self.runner.hash, runner.hash,
                   @"The two instances should have equal hash because they are equal");
}

- (void)testMainDispatchQueueBlockRunnerShouldCreateMainQueueInstance {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    DispatchQueueBlockRunner *manualMainQueueRunner = [[DispatchQueueBlockRunner alloc]
                                                 initWithDispatchQueue:mainQueue];

    DispatchQueueBlockRunner *convenienceMainQueueRunner = [DispatchQueueBlockRunner mainQueueRunner];
    XCTAssertEqualObjects(manualMainQueueRunner, convenienceMainQueueRunner,
                          @"The mainQueueRunner should return runner with main queue");
}

@end
