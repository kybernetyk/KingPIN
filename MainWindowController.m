//
//  MainWindowController.m
//  KingPIN
//
//  Created by jrk on 19.12.09.
//  Copyright 2009 flux forge. All rights reserved.
//
//
//	Licensed under the BSD license. See 'BSD License.txt'
//

#import "MainWindowController.h"
#import "AMSerialPort.h"
#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"
#import "NSString+Search.h"

@implementation MainWindowController

/**
 get a list of active serial ports and fill them into our datasource for the table view
 */
- (void) enumerateSerialDevices
{
	[enumeratedDevices release];
	enumeratedDevices = nil;
	
	NSMutableArray *tmp = [NSMutableArray arrayWithCapacity: 5];
	
	NSEnumerator *enumerator = [AMSerialPortList portEnumerator];
	AMSerialPort *aPort;
	while (aPort = [enumerator nextObject]) 
	{
		NSDictionary *device = [NSDictionary dictionaryWithObjectsAndKeys: 
								[NSString stringWithString: [aPort name]],@"name",
								[NSString stringWithString: [aPort bsdPath]] , @"path",
								nil];

		[tmp addObject: device];
		
		NSLog(@"found port with name %@ and path %@",[aPort name], [aPort bsdPath]);
	}
	enumeratedDevices = [[NSArray alloc] initWithArray: tmp];
	
	
	NSString *lastUsedDevice = [[NSUserDefaults standardUserDefaults] objectForKey: @"lastUsedDevice"];
	NSInteger rowToSelect = 0;
	BOOL selectRow = NO;
	if (lastUsedDevice)
	{
		unsigned int i = 0;
		for (NSDictionary *dict in enumeratedDevices)
		{
			if ([[dict objectForKey: @"name"] isEqualToString: lastUsedDevice])
			{
				NSLog(@"selecting last used device: %@", lastUsedDevice);
				//[tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: i] byExtendingSelection: NO];
				rowToSelect = i;
				selectRow = YES;
				break;
			}
			i++;
		}
		
		[tableView reloadData];

		//we must set this after reloadData as a reloadData triggers a didSelect: notification from the tableView
		//which would overwrite our selection and select item 0
		if (selectRow)
		{
			[tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: rowToSelect] byExtendingSelection: NO];
		}
	}
}

- (void) awakeFromNib
{
	errored = NO;
	NSDictionary *defs = [NSDictionary dictionaryWithObjectsAndKeys: @"Your Pin", @"lastUsedPin", nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults: defs];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddPorts:) name:AMSerialPortListDidAddPortsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovePorts:) name:AMSerialPortListDidRemovePortsNotification object:nil];
	
	[AMSerialPortList sharedPortList]; // initialize port list to arm notifications

	
	[self enumerateSerialDevices];
	wrongPinEntries = 0;
}

#pragma mark -
#pragma mark IBActions
- (IBAction) sendPin: (id) sender
{
	errored = NO;
	if (wrongPinEntries >= 2)
	{
		NSAlert *al = [NSAlert alertWithMessageText: @"PIN error warning."
									  defaultButton: @"Ok" 
									alternateButton: nil
										otherButton: nil
						  informativeTextWithFormat: @"You have entered the wrong PIN twice. Please disconnect and reconnect the modem from your mac to reset the counter. Entering the wrong PIN three times without a reset will most likely disable the SIM card.", nil];
		[al runModal];
		return;
	}
	
	NSInteger selectedRow = [tableView selectedRow];
	NSDictionary *device = [enumeratedDevices objectAtIndex: selectedRow];
	
	NSString *deviceName = [device objectForKey: @"name"];
	NSString *devicePath = [device objectForKey: @"path"];
	NSString *pinString =  [[NSUserDefaults standardUserDefaults] stringForKey: @"lastUsedPin"];
	
	//[[NSUserDefaults standardUserDefaults] setObject: deviceName forKey: @"lastUsedDevice"];
	
	NSLog(@"sending pin %@ to device %@", pinString, devicePath );
	
	//close any other connections
	[serialPort close];
	[serialPort release];
	serialPort = nil;
	
	
	serialPort = [[AMSerialPort alloc] init: devicePath withName: deviceName type: (NSString*)CFSTR(kIOSerialBSDModemType)];
	[serialPort setEchoEnabled: NO];
	[serialPort setDelegate: self];
	

	NSLog(@"opening port %@", devicePath);
	
	[statusBar setStringValue: [NSString stringWithFormat: @"Opening port %@ ...", devicePath]];
	
	// open port - may take a few seconds ...
	if ([serialPort open]) 
	{
		//NSLog(@"port open.");
		
		[statusBar setStringValue: [NSString stringWithFormat: @"Port opened."]];

		// listen for data asynchronous 
		[serialPort readDataInBackground];
		
		
		if([serialPort isOpen]) 
		{ // in case an error occured while opening the port
			pinString = [NSString stringWithFormat: @"AT+CPIN=%@\r",pinString];
			//NSLog(@"sending %@ ...", pinString);
			[statusBar setStringValue: [NSString stringWithFormat: @"Sending %@ ...", pinString]];
			[serialPort writeString: pinString usingEncoding:NSUTF8StringEncoding error:NULL];
		}
		else
		{	
			[statusBar setStringValue: [NSString stringWithFormat: @"Error: Port closed."]];
			NSLog(@"port %@ was closed?!", devicePath);
			[serialPort release];
			serialPort = nil;
		}
		
	} 
	else 
	{ 
		[statusBar setStringValue: [NSString stringWithFormat: @"Error: Could not open port %@ ...", devicePath]];
		NSLog(@"could not open port %@", devicePath);
		[serialPort release];
		serialPort = nil;
	}
	
}

#pragma mark -
#pragma mark serial port delegate / notifications
- (void)serialPortReadData:(NSDictionary *)dataDictionary
{
	// this method is called if data arrives 
	// @"data" is the actual data, @"serialPort" is the sending port
	AMSerialPort *sendPort = [dataDictionary objectForKey:@"serialPort"];
	NSData *data = [dataDictionary objectForKey:@"data"];

	if ([data length] > 0) 
	{
		NSString *text = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		NSLog(@"received data from serial port:");
		NSLog(@"%@",text);
		
		BOOL continueReading = YES;

		if ([text containsString: @"error" ignoringCase: YES] ||
			[text containsString: @"OK" ignoringCase: YES])
		{
			continueReading = NO;
			if ([text containsString: @"error" ignoringCase: YES])
			{
				NSAlert *al = [NSAlert alertWithMessageText: @"Setting the PIN failed."
											  defaultButton: @"Ok" 
											alternateButton: nil
												otherButton: nil
								  informativeTextWithFormat: @"The modem returned an error: %@", text,nil];
				wrongPinEntries ++;
				[al runModal];
			}
			[statusBar setStringValue: [NSString stringWithFormat: @"Error: %@", text]];
			errored = YES;
		}
		[text release];

		
		// continue listening
		if (continueReading)
		{
			NSLog(@"there is more coming ...");
			[sendPort readDataInBackground];
		}
		else
		{
			if (!errored)
				[statusBar setStringValue: [NSString stringWithFormat: @"Succes."]];
			//we got an OK or ERROR so we close the connection to let other apps use the port
			NSLog(@"port empty. release!");
			[serialPort close];
			[serialPort autorelease];
			serialPort = nil;
		}
	} 
	else 
	{ 
		NSLog(@"port closed");
		[serialPort autorelease];
		serialPort = nil;
	}
}

- (void) didAddPorts: (NSNotification *) notification
{
	NSLog(@"new serial ports were added. updating list!");
	
	[self enumerateSerialDevices];
}

- (void) didRemovePorts: (NSNotification *) notification
{
	NSLog(@"serial port was removed. updating list!");
	
	[self enumerateSerialDevices];
}


#pragma mark -
#pragma mark tableview datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{

	return [enumeratedDevices count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [[enumeratedDevices objectAtIndex: rowIndex] objectForKey: @"name"];
}

#pragma mark -
#pragma mark tableview delegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger selectedRow = [tableView selectedRow];
	if (selectedRow >= 0 && selectedRow < [enumeratedDevices count])
	{
		wrongPinEntries = 0;
		NSInteger selectedRow = [tableView selectedRow];
		NSDictionary *device = [enumeratedDevices objectAtIndex: selectedRow];
		
		NSString *deviceName = [device objectForKey: @"name"];
		//NSString *devicePath = [device objectForKey: @"path"];
	//	NSString *pinString =  [[NSUserDefaults standardUserDefaults] stringForKey: @"lastUsedPin"];
		
		[[NSUserDefaults standardUserDefaults] setObject: deviceName forKey: @"lastUsedDevice"];
		
	}
}

- (void)windowWillClose:(NSNotification *)notification {
	NSNotificationCenter *c = [NSNotificationCenter defaultCenter];
	[c postNotificationName: @"window_will_close" object: self];
//	[self autorelease];
}

- (void) windowDidLoad
{
	NSLog(@"window did load!");
//	[[self window] makeKeyWindow];
	NSLog(@"can? %@", [self window]);
}

@end
