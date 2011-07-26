//
//  KingPINAppDelegate.h
//  KingPIN
//
//  Created by jrk on 19.12.09.
//  Copyright 2009 flux forge. All rights reserved.
//
//
//	Licensed under the BSD license. See 'BSD License.txt'
//

#import <Cocoa/Cocoa.h>
#import "MainWindowController.h"
#import "FXKingPinWindow.h"

@interface KingPINAppDelegate : NSObject <NSApplicationDelegate> 
{
	int num_of_windows;
	
	IBOutlet MainWindowController *mwc;
	IBOutlet FXKingPinWindow *window;
}

- (IBAction) repopenWindow: (id) sender;

@end
