//
//  StateTests.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 04/12/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

@interface StateTests : XCTestCase
{
    Client * client;
}
@end

@implementation StateTests
-(void)setUp {
    struct ClientConfiguration configuration;
    configuration.port = 5001;
    configuration.eventLoopMicrosecondsDelay = 50;
    configuration.connectionTimeout = 5;
    configuration.chunkSize = 50;
    configuration.address = "localhost";
    client = [[Client alloc] initWithConfiguration:configuration];
}
-(void)testInitialState {
    XCTAssertFalse([client isRunning]);
    [client boot];
    NSPredicate * clientRunning = [NSPredicate predicateWithFormat:@"isRunning == YES"];
    [self waitForExpectations:@[[self expectationForPredicate:clientRunning
                                          evaluatedWithObject:client
                                                      handler:nil]] timeout:10];
    [client shutDown:YES];
    XCTAssertFalse([client isRunning]);
}
@end