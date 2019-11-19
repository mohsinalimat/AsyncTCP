//
//  ResourceLock.h
//  AsyncTCP
//
//  Created by Mateusz Stompór on 19/11/2019.
//  Copyright © 2019 Mateusz Stompór. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Lockable.h"

NS_ASSUME_NONNULL_BEGIN

@interface ResourceLock: NSObject<Lockable>
@end

NS_ASSUME_NONNULL_END
