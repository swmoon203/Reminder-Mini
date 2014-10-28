//
//  ListRowViewController.h
//  Reminders Mini
//
//  Created by mtjddnr on 2014. 10. 28..
//  Copyright (c) 2014년 mtjddnr. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EventKit/EventKit.h>

@interface ListRowViewController : NSViewController
@property (weak) IBOutlet NSTextField *txtTitle;
@property (weak) IBOutlet NSTextField *txtDate;
@property (weak) IBOutlet NSButton *complete;

@property (weak) EKEventStore *store;
@property (weak, readonly) EKReminder *reminder;

@end
