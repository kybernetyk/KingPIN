//
//  KingPINAppDelegate.m
//  KingPIN
//
//  Created by jrk on 19.12.09.
//  Copyright 2009 flux forge. All rights reserved.
//
//
//	Licensed under the BSD license. See 'BSD License.txt'
//

#import "KingPINAppDelegate.h"
#import "MainWindowController.h"
@implementation KingPINAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	NSNotificationCenter *c = [NSNotificationCenter defaultCenter];
	//[c postNotificationName: @"window_will_close" object: self];
	[c addObserver: self selector: @selector(notificaitonshit:) name: @"window_will_close" object:nil];
	num_of_windows = 1;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
//	if (num_of_windows <= 0) {
//		num_of_windows++;
//		MainWindowController *mwc = [[MainWindowController alloc] initWithWindowNibName: @"MainMenu"];
//		[[mwc window] makeKeyAndOrderFront: [mwc window]];
//	}
	
	[mwc showWindow: self];
}


- (void) notificaitonshit: (NSNotification *) notification
{
	if ([[notification name] isEqualToString: @"window_will_close"]) {
		num_of_windows--;
	}
}

- (IBAction) repopenWindow: (id) sender 
{
	[mwc showWindow: self];
//	if (num_of_windows <= 0) {
//		num_of_windows++;
//		MainWindowController *mwc = [[MainWindowController alloc] initWithWindowNibName: @"MainMenu"];
//		[[mwc window] makeKeyAndOrderFront: [mwc window]];
//	}
}

@end
