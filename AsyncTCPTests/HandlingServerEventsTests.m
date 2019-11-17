//
//  TestHandlingServerEvents.m
//  AsyncTCPTests
//
//  Created by Mateusz Stompór on 06/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <netdb.h>
#import <XCTest/XCTest.h>
#import <AsyncTCP/AsyncTCP.h>

#import "TestsClient.h"
#import "ServerHandler.h"

@interface ServerEventsTests: XCTestCase
{
    NSObject<ServerHandle> * asyncServer;
    ServerHandler * serverHandler;
    TestsClient * client;
    TestsClient * anotherClient;
    struct ServerConfiguration configuration;
}
@end

@implementation ServerEventsTests
-(void)setUp {
    configuration.port = 47856;
    configuration.chunkSize = 36;
    configuration.connectionTimeout = 5;
    configuration.maximalConnectionsCount = 1;
    configuration.eventLoopMicrosecondsDelay = 400;
    serverHandler = [[ServerHandler alloc] init];
    asyncServer = [[Server alloc] initWithConfiguratoin:configuration
                                      notificationQueue:dispatch_get_global_queue(0, 0)];
    client = [[TestsClient alloc] initWithHost:"localhost" port:47856];
    anotherClient = [[TestsClient alloc] initWithHost:"localhost" port:47856];
}
-(void)testReceivingEvents {
    asyncServer.delegate = serverHandler;
    [asyncServer boot];
    if ([client connect] < 0) {
        XCTFail("Port is closed");
    }
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        sleep(1);
        dispatch_async(dispatch_get_main_queue(), ^{
            XCTAssertNotNil(self->serverHandler.lastConnection);
            XCTAssertEqual([self->serverHandler.lastConnection state], active);
        });
    });
    dispatch_group_notify(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->asyncServer shutDown];
            XCTAssertEqual([self->serverHandler.lastConnection state], closed);
        });
    });
}
@end
