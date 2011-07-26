//
//  FXKingPinWindow.m
//  KingPIN
//
//  Created by jrk on 26/7/11.
//  Copyright 2011 Flux Forge. All rights reserved.
//

#import "FXKingPinWindow.h"


@implementation FXKingPinWindow

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (BOOL) canBecomeKeyWindow {
	return YES;
}

- (BOOL) canBecomeMainWindow {
	return YES;
}

@end
