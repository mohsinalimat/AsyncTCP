//
//  Connection.m
//  AsyncTCP
//
//  Created by Mateusz Stompór on 05/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import "Connection.h"

#import <netdb.h>
#import <errno.h>
#import <stdint.h>
#import <sys/types.h>
#import <sys/socket.h>

#import "ResourceLock.h"
#import "NetworkManager.h"
#import "NetworkWrapper.h"
#import "IONetworkHandler.h"
#import "ConnectionDelegate.h"


@interface Connection()
{
    ssize_t chunkSize;
    NSDate* lastActivity;
    NSMutableData* buffer;
    NSObject<Lockable>* resourceLock;
    ConnectionState state;
    Identity * identity;
    NSMutableArray<NSData*>* outgoingMessages;
    NSObject<NetworkManageable>* networkManager;
    dispatch_queue_t notificationQueue;
}
@end

@implementation Connection
@synthesize delegate=_delegate;
-(instancetype)initWithIdentity: (Identity*) identity
                      chunkSize: (ssize_t) chunkSize
              notificationQueue: (dispatch_queue_t) notificationQueue
                 networkManager: (NSObject<NetworkManageable>*) networkManager
                   resourceLock: (NSObject<Lockable>*) resourceLock {
    self = [super init];
    if (self) {
        self->identity = identity;
        self->resourceLock = resourceLock;
        self->lastActivity = [NSDate new];
        self->buffer = [NSMutableData new];
        self->chunkSize = chunkSize;
        self->notificationQueue = notificationQueue;
        self->state = active;
        self->networkManager = networkManager;
        self->outgoingMessages = [NSMutableArray new];
    }
    return self;
}
-(BOOL)enqueueDataForSending: (NSData*) data {
    [resourceLock aquireLock];
    if (state == active) {
        [outgoingMessages addObject:data];
        [resourceLock aquireLock];
        return YES;
    } else {
        [resourceLock releaseLock];
        return NO;
    }
}
-(void)close {
    BOOL notifyDelegate = NO;
    [resourceLock aquireLock];
    if(state != closed) {
        notifyDelegate = YES;
        [self unsafeClose];
    }
    [resourceLock releaseLock];
    __weak Connection * weakSelf = self;
    if (weakSelf == nil || notifyDelegate == NO) {
        return;
    }
    dispatch_async(notificationQueue, ^{
        [weakSelf.delegate connection:weakSelf stateHasChangedTo:weakSelf.state];
    });
}
-(void)unsafeClose {
    state = closed;
    [networkManager close:identity];
}
-(ConnectionState)state {
    [resourceLock aquireLock];
    ConnectionState stateToReturn = state;
    [resourceLock releaseLock];
    return stateToReturn;
}
-(NSTimeInterval)lastInteractionInterval {
    [resourceLock aquireLock];
    NSTimeInterval interval = [[NSDate new] timeIntervalSinceDate:lastActivity];
    [resourceLock releaseLock];
    return interval;
}
-(NSData*)buffer {
    [resourceLock aquireLock];
    NSData* currentBuffer = [buffer copy];
    [resourceLock releaseLock];
    return currentBuffer;
}
-(void)performIO {
    [resourceLock aquireLock];
    NSData * dataToSent = nil;
    BOOL stateChanged = NO;
    @try {
        if ([outgoingMessages count] > 0) {
            NSData * data = [outgoingMessages objectAtIndex:0];
            [outgoingMessages removeObjectAtIndex:0];
            lastActivity = [NSDate new];
            NSData * dataLeft = [networkManager send:data identity:identity];
            if (dataLeft) {
                [outgoingMessages insertObject:dataLeft atIndex:0];
            }
        }
        NSData * dataRead = [networkManager readBytes:chunkSize identity:identity];
        if(dataRead) {
            lastActivity = [NSDate new];
            [buffer appendData:dataRead];
            if([buffer length] >= chunkSize) {
                dataToSent = [buffer subdataWithRange:NSMakeRange(0, chunkSize)];
                buffer = [[buffer subdataWithRange:NSMakeRange(chunkSize, [buffer length] - chunkSize)] mutableCopy];
            }
        }
    } @catch (IOException *exception) {
        [self unsafeClose];
        stateChanged = YES;
    }
    [resourceLock releaseLock];
    __weak Connection * weakSelf = self;
    if (dataToSent) {
        dispatch_async(notificationQueue, ^{
            [weakSelf.delegate connection:weakSelf chunkHasArrived:dataToSent];
        });
    }
    if (stateChanged) {
        dispatch_async(notificationQueue, ^{
            [weakSelf.delegate connection:weakSelf stateHasChangedTo:weakSelf.state];
        });
    }
}
@end
