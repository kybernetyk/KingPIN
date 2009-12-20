//
//  MainWindowController.h
//  KingPIN
//
//  Created by jrk on 19.12.09.
//  Copyright 2009 flux forge. All rights reserved.
//
//	Licensed under the BSD license. See 'BSD License.txt'
//

#import <Cocoa/Cocoa.h>
#import "AMSerialPort.h"

/**
 the controller for our main window.
 an instance is created in MainMenu.xib
 */
@interface MainWindowController : NSWindowController 
{
	IBOutlet NSTableView *tableView;
	
	AMSerialPort *serialPort;
	NSInteger wrongPinEntries;
	NSArray *enumeratedDevices;

}

- (void) enumerateSerialDevices;
- (IBAction) sendPin: (id) sender;
@end
