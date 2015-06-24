//
//  AppDelegate.m
//  LitePipe Sample app delegate
//
//  Copyright (c) 2015 Linn Products Limited. All rights reserved.
//

#import "AppDelegate.h"

#include "SampleMediaPlayer.h"

@interface AppDelegate ()

- (IBAction)saveAction:(id)sender;

@end

@implementation AppDelegate

OpenHome::Av::Sample::SampleMediaPlayer *samplePlayer;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // we have finished launching the app so create our status menu
    // The app has been configured without a main window by setting
    // the 'Application is agent' property in info.plist
    // and not having a main window or view controller
    [self setupStatusItem];
    
    samplePlayer = new OpenHome::Av::Sample::SampleMediaPlayer();
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    delete samplePlayer;
}


- (void)setupStatusItem
{
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.title = @"";
    _statusItem.image = [NSImage imageNamed:@"menu"];
    _statusItem.alternateImage = [NSImage imageNamed:@"menu-hilite"];
    _statusItem.highlightMode = YES;
    
    [self initMenu];
}

- (void)initMenu
{
    // create a menu 
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Check for updates" action:@selector(checkUpdates:) keyEquivalent:@""];
    [menu addItemWithTitle:@"About" action:@selector(about:) keyEquivalent:@""];

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Play" action:@selector(lp_play:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Pause" action:@selector(lp_pause:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Stop" action:@selector(lp_stop:) keyEquivalent:@""];
    
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Quit Linn Sample" action:@selector(terminate:) keyEquivalent:@""];
    
    self.statusItem.menu = menu;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];
    
    // enable our player menu items based on the current mediaplayer state
    // note that we must check with the player as it may have been paused/played
    // by external controlpoints, and the mediaplayer monitors the playback
    // state directly so should always be up to date
    if (theAction == @selector(lp_pause:)) {
        return( samplePlayer->canPause() ? YES : NO );
    }
    else if (theAction == @selector(lp_play:)) {
        return( samplePlayer->canPlay() ? YES : NO );
    }
    else if (theAction == @selector(lp_stop:)) {
        return( samplePlayer->canStop() ? YES : NO );
    }
    
    // all our other menu items should always be enabled
    return YES;
}


- (void)checkUpdates:(id)sender
{
}

- (void)lp_play:(id)sender
{
    if(samplePlayer != nil)
        samplePlayer->play();
}

- (void)lp_pause:(id)sender
{
    if(samplePlayer != nil)
        samplePlayer->pause();
}

- (void)lp_stop:(id)sender
{
    if(samplePlayer != nil)
        samplePlayer->stop();
}

- (void)about:(id) sender
{
    // invoke the standard Cocoa about box using details
    // pulled from the app resources
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:self];
}


#pragma mark - Core Data stack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;


- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.openhome.litepipe.sample" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.openhome.litepipe.sample"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"OSXCoreDataObjC.storedata"];
        if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
            coordinator = nil;
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

#pragma mark - Core Data Saving and Undo support

- (IBAction)saveAction:(id)sender {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

@end
