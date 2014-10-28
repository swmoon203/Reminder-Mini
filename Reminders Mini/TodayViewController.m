//
//  TodayViewController.m
//  Reminders Mini
//
//  Created by mtjddnr on 2014. 10. 28..
//  Copyright (c) 2014년 mtjddnr. All rights reserved.
//

#import "TodayViewController.h"
#import "ListRowViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <EventKit/EventKit.h>

@interface TodayViewController () <NCWidgetProviding, NCWidgetListViewDelegate>

@property (strong) IBOutlet NCWidgetListViewController *listViewController;
@property (strong) EKEventStore *eventStore;

@end


@implementation TodayViewController {
    BOOL _needReload;
}

#pragma mark - NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up the widget list view controller.
    // The contents property should contain an object for each row in the list.
    //self.listViewController.contents = @[@"Hello World!"];
    if (_eventStore == nil) {
        _eventStore = [[EKEventStore alloc] init];
    }
    
    self.listViewController.minimumVisibleRowCount = 5;
    [self loadReminders];
}

- (void)loadReminders {
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
    switch (status) {
        case EKAuthorizationStatusNotDetermined: {
            [_eventStore requestAccessToEntityType:EKEntityTypeReminder
                                        completion:^(BOOL granted, NSError *error) {
                                            if (granted) [self loadReminders];
                                        }];
            break;
        }
        case EKAuthorizationStatusAuthorized:
            break;
        default:
            return;
            break;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChangeReminder:) name:EKEventStoreChangedNotification object:_eventStore];
    

    NSPredicate *predicate = [_eventStore predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:nil];
    
    [_eventStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *incompleteReminders) {
        NSMutableArray *list = [NSMutableArray array];
        [list addObjectsFromArray:incompleteReminders];
        
        NSPredicate *predicate = [_eventStore predicateForRemindersInCalendars:nil];
        [_eventStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders) {
            NSMutableArray *completeReminders = [NSMutableArray array];
            
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = -7;
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDate *startDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
            

            for (EKReminder *reminder in reminders) {
                if (reminder.isCompleted && [startDate compare:reminder.completionDate] != NSOrderedDescending) {
                    [completeReminders addObject:reminder];
                }
            }
            
            [completeReminders sortedArrayUsingComparator:^(EKReminder *obj1, EKReminder *obj2) {
                return [obj2.completionDate compare:obj1.completionDate];
            }];
            
            
            NSUInteger incompleteCount = [list count];
            [list addObjectsFromArray:completeReminders];

            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([self.listViewController.contents count] > 0) {
                    //need to check
                    for (EKReminder *r in self.listViewController.contents) {
                        EKReminder *found = nil;
                        for (EKReminder *i in list) {
                            if ([r.calendarItemIdentifier isEqualToString:i.calendarItemIdentifier]) {
                                found = i;
                                break;
                            }
                        }
                        if (found) {
                            [list removeObject:found];
                        }
                    }
                    
                    if ([list count] != 0) {
                        self.listViewController.minimumVisibleRowCount = incompleteCount;
                        self.listViewController.contents = list;
                    }
                } else {
                    self.listViewController.minimumVisibleRowCount = incompleteCount;
                    self.listViewController.contents = list;
                }
                
                
                //self.listViewController.minimumVisibleRowCount = incompleteCount;
                //self.listViewController.contents = list;
                
            });
        }];
        
    }];
}

- (void)onChangeReminder:(NSNotification *)notification {
    NSLog(@"onChangeReminder: %@", notification.userInfo);
    _needReload = YES;
    [self loadReminders];
}

- (void)dismissViewController:(NSViewController *)viewController {
    [super dismissViewController:viewController];
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    NSLog(@"widgetPerformUpdateWithCompletionHandler: %i", _needReload);
    // Refresh the widget's contents in preparation for a snapshot.
    // Call the completion handler block after the widget's contents have been
    // refreshed. Pass NCUpdateResultNoData to indicate that nothing has changed
    // or NCUpdateResultNewData to indicate that there is new data since the
    // last invocation of this method.
    if (_needReload == NO) {
        completionHandler(NCUpdateResultNoData);
    } else {
        [self loadReminders];
        _needReload = NO;
        completionHandler(NCUpdateResultNewData);
    }
}

- (NSEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(NSEdgeInsets)defaultMarginInset {
    // Override the left margin so that the list view is flush with the edge.
    defaultMarginInset.left = -30.0f;
    defaultMarginInset.right = -10.0f;
    return defaultMarginInset;
}

- (BOOL)widgetAllowsEditing {
    return NO;
}

- (void)widgetDidBeginEditing {
    // The user has clicked the edit button.
    // Put the list view into editing mode.
    //self.listViewController.editing = YES;
}

- (void)widgetDidEndEditing {
    // The user has clicked the Done button, begun editing another widget,
    // or the Notification Center has been closed.
    // Take the list view out of editing mode.
    //self.listViewController.editing = NO;
}

#pragma mark - NCWidgetListViewDelegate

- (NSViewController *)widgetList:(NCWidgetListViewController *)list viewControllerForRow:(NSUInteger)row {
    // Return a new view controller subclass for displaying an item of widget
    // content. The NCWidgetListViewController will set the representedObject
    // of this view controller to one of the objects in its contents array.
    ListRowViewController *vc = [[ListRowViewController alloc] init];
    vc.store = self.eventStore;
    return vc;
}

- (void)widgetListPerformAddAction:(NCWidgetListViewController *)list {
    // The user has clicked the add button in the list view.
    // Display a search controller for adding new content to the widget.
    //self.searchController = [[NCWidgetSearchViewController alloc] init];
    //self.searchController.delegate = self;

    // Present the search view controller with an animation.
    // Implement dismissViewController to observe when the view controller
    // has been dismissed and is no longer needed.
    //[self presentViewControllerInWidget:self.searchController];
}

- (BOOL)widgetList:(NCWidgetListViewController *)list shouldReorderRow:(NSUInteger)row {
    // Return YES to allow the item to be reordered in the list by the user.
    return YES;
}

- (void)widgetList:(NCWidgetListViewController *)list didReorderRow:(NSUInteger)row toRow:(NSUInteger)newIndex {
    // The user has reordered an item in the list.
}

- (BOOL)widgetList:(NCWidgetListViewController *)list shouldRemoveRow:(NSUInteger)row {
    // Return YES to allow the item to be removed from the list by the user.
    return YES;
}

- (void)widgetList:(NCWidgetListViewController *)list didRemoveRow:(NSUInteger)row {
    // The user has removed an item from the list.
}

#pragma mark - NCWidgetSearchViewDelegate

- (void)widgetSearch:(NCWidgetSearchViewController *)searchController searchForTerm:(NSString *)searchTerm maxResults:(NSUInteger)max {
    // The user has entered a search term. Set the controller's searchResults property to the matching items.
    searchController.searchResults = @[];
}

- (void)widgetSearchTermCleared:(NCWidgetSearchViewController *)searchController {
    // The user has cleared the search field. Remove the search results.
    searchController.searchResults = nil;
}

- (void)widgetSearch:(NCWidgetSearchViewController *)searchController resultSelected:(id)object {
    // The user has selected a search result from the list.
}

@end
