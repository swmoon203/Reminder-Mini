//
//  ListRowViewController.m
//  Reminders Mini
//
//  Created by mtjddnr on 2014. 10. 28..
//  Copyright (c) 2014년 mtjddnr. All rights reserved.
//

#import "ListRowViewController.h"

@implementation ListRowViewController
- (EKReminder *)reminder {
    return self.representedObject;
}

- (NSString *)nibName {
    return @"ListRowViewController";
}

- (void)viewWillAppear {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChangeReminder:) name:EKEventStoreChangedNotification object:self.store];
    
    [self updateView];
}

- (void)updateView {
    self.txtTitle.stringValue = self.reminder.title;
    if (self.reminder.isCompleted) {
        if (self.reminder.completionDate) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterShortStyle;
            NSString *dateString = [formatter stringFromDate:self.reminder.completionDate];
            self.txtDate.stringValue = dateString;
        } else {
            self.txtDate.stringValue = @"";
        }
        self.complete.state = NSOnState;
    } else {
        if (self.reminder.dueDateComponents) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterShortStyle;
            NSDate *someDate = [[NSCalendar currentCalendar] dateFromComponents:self.reminder.dueDateComponents];
            NSString *dateString = [formatter stringFromDate:someDate];
            self.txtDate.stringValue = dateString;
        } else {
            self.txtDate.stringValue = @"";
        }
        self.complete.state = NSOffState;
    }
}

- (IBAction)onChangeState:(id)sender {
    BOOL oldState = self.reminder.isCompleted;
    self.reminder.completed = !oldState;
    if ([self.store saveReminder:self.reminder commit:YES error:nil] == NO) {
            [self.reminder refresh];
    }
    self.complete.state = self.reminder.isCompleted ? NSOnState : NSOffState;
}

- (void)onChangeReminder:(NSNotification *)notification {
    if ([self.reminder refresh]) {
        [self updateView];
    }
}
@end
