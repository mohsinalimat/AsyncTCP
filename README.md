<p align="center">
  <img src="https://github.com/mateuszstompor/AsyncTCP/blob/master/Assets/icon.png?raw=true" width="40%">
</p>
<h1 align="center">AsyncTCP</h1>
<p align="center">    
    <a href="https://cocoapods.org/pods/AsyncTCP">
        <img src="https://img.shields.io/cocoapods/v/AsyncTCP" height="18pt" alt="Cocoapod"/>
    </a>
    <a href="https://codecov.io/gh/mateuszstompor/AsyncTCP">
        <img src="https://codecov.io/gh/mateuszstompor/AsyncTCP/branch/master/graph/badge.svg" height="18pt" alt="Coverage"/>
    </a>
    <a href="https://opensource.org/licenses/MIT">
        <img src="https://img.shields.io/badge/License-MIT-yellow.svg" height="18pt" alt="License"/>
    </a>
    <a href="https://www.travis-ci.org/mateuszstompor/AsyncTCP">
        <img src="https://www.travis-ci.org/mateuszstompor/AsyncTCP.svg?branch=master" height="18pt" alt="Build status"/>
    </a>
</p>

## About

A tiny library easing TCP connections handling. Provides a set of classes for the user to connect to a remote server as a client and is able to host a server on its own.

Non-blocking and asynchronous, uses delegation to notify about incoming data packets, connection state change, etc. Gives you a choice which dispatch queue you'd like to choose to receive the notifications. 

All components are loosly coupled, as a result the code is testable and **tested**.


# Examples
### Setting up a server
First of all define server's boot parameters
```objective-c
struct ServerConfiguration configuration;
// Port is a number in range from 0 to 65535
configuration.port = 47851;
// Chunk size is a buffer size
configuration.chunkSize = 36;
// Time of inactivity after which client's connection is going to be closed
configuration.connectionTimeout = 5;
// Number of clients allowed to connect
configuration.maximalConnectionsCount = 1;
// Interval between server's main loop evaluations. Adjust depending on your network speed and device's resources utilization
configuration.eventLoopMicrosecondsDelay = 20;
// Number of errors after which the connection will be closed
configuration.errorsBeforeConnectionClosing = 3;
```
Create a server with this specific configuration. By default all notification will be passed to the main dispatch queue.
```objective-c
NSObject<ServerHandle> * asyncServer = [[Server alloc] initWithConfiguratoin:configuration];
```
Notifications will be send only if the delegate of the server is set. Otherwise connections won't be accepted and data received. To receive notifications implement `ServerDelegate` protocol.
<h4>ServerDelegate</h4>

**Interface**
```objective-c
@interface ServerHandler: NSObject<ServerDelegate>
@end
```
**Implementation**
```objective-c
@implementation ServerHandler
-(void)newClientHasConnected: (Connection*) connection {
    // Handle the connection here somehow
}
-(void)clientHasDisconnected: (Connection*) connection {
    // Ivoked when a client disconnected or the connection hung 
}
@end
```
One additional step to make is to implement `ConnectionDelegate` protocol. It is an interface which lets you receive a notification when data is received or connection's state updated.
<h4>ConnectionDelegate</h4>

**Interface**
```objective-c
@interface ConnectionHandler: NSObject<ConnectionDelegate>
@end
```
**Implementation**
```objective-c
@implementation ConnectionHandler
-(void)connection:(NSObject<ConnectionHandle> *)connection chunkHasArrived:(NSData *)data {
    // Parse the data or pass it through 
}
@end
```