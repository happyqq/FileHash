//
//  HQQ_AppDelegate.m
//  FileHash
//
//  Created by 黄启清 on 13-11-14.
//  Copyright (c) 2013年 黄启清. All rights reserved.
//

#import "HQQ_AppDelegate.h"
#import "FileMD5Hash.h"
#import "NSString+NSHash.h"
#import "CocoaSecurity.h"

@implementation HQQ_AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    NSString *strUrl = @"http://happyqq.cn/WebSite_AD/CheckSum/";
    
    [[_web mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]]];
    
    [_cmbType setStringValue:@"MD5"];
    [_cmbType selectItemWithObjectValue:@"MD5"];
    
    [_cmbTypeC setStringValue:@"MD5"];
    [_cmbTypeC selectItemWithObjectValue:@"MD5"];
    
    [_txtCompareResult setStringValue:@""];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "HappyQQ.cn.FileHash" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"HappyQQ.cn.FileHash"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"FileHash" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"FileHash.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
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
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

- (void) openPanelDidEnd: (NSOpenPanel *) sheet
              returnCode: (int) returnCode
             contextInfo: (void *) context
{
    // 2a68a26c77815a7fcc72fb897b86c317
    if (returnCode == NSOKButton) {
        NSArray *fileNames = [sheet filenames];
        
        //NSLog (@"ooxx: %@", [fileNames objectAtIndex: 0]);
        
        
        //NSString *filePath = [[NSBundle mainBundle] executablePath];
        //NSString *filePath = @"/Users/HappyQQ/downloads/test/lemon.c";
        /*--------------
         NSString *filePath = [fileNames objectAtIndex: 0];
         [_txtFilePath setStringValue:filePath];
         CFStringRef executableFileMD5Hash =
         FileMD5HashCreateWithPath((__bridge CFStringRef)filePath,
         FileHashDefaultChunkSizeForReadingData);
         if (executableFileMD5Hash) {
         [_txtResult setStringValue:(__bridge NSString *)(executableFileMD5Hash)];
         //CFRelease(executableFileMD5Hash);
         }
         
         */
        NSString *truefilePath = [fileNames objectAtIndex: 0];
        [_txtFilePath setStringValue:truefilePath];
        [_txtCompareResult setStringValue:@""];
        NSData *data;
        data = [NSData dataWithContentsOfFile: truefilePath];
        
        NSString *selvalue = [_cmbType stringValue];
        
        if([selvalue isEqualToString:@"MD5"])
        {
            //-----md5 begin here ------------------
            CocoaSecurityResult *md5 = [CocoaSecurity md5WithData:data];
            
            NSString *result_md5 = md5.hex;
            [_txtResult setStringValue:result_md5];
            //------md5 end here
        }
        else if([selvalue isEqualToString:@"SHA1"])
        {
            //-----sha1 begin here ------------------
            CocoaSecurityResult *sha1 = [CocoaSecurity sha1WithData:data];
            
            NSString *result_sha1 = sha1.hex;
            [_txtResult setStringValue:result_sha1];
            //------sha1 end here
        }
        else if([selvalue isEqualToString:@"SHA256"])
        {
            //-----sha256 begin here ------------------
            CocoaSecurityResult *sha256 = [CocoaSecurity sha256WithData:data];
            
            NSString *result_sha256 = sha256.hex;
            [_txtResult setStringValue:result_sha256];
            //------sha256 end here
        }
        else if([selvalue isEqualToString:@"SHA512"])
        {
            //-----sha512 begin here ------------------
            CocoaSecurityResult *sha512 = [CocoaSecurity sha512WithData:data];
            
            NSString *result_sha512 = sha512.hex;
            [_txtResult setStringValue:result_sha512];
            //------sha512 end here
        }
    }
    
}

- (IBAction)btnSelect:(id)sender {
    //char s[100] = "/Users/HappyQQ/downloads/test/laemon.c";
    //calc_crc(s);
    //char *Cstring = "This is a String!";
    //NSString *astring = [[NSString alloc]initWithCString:Cstring];
    //[_lblCrc setStringValue:@"abc"];
    
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setPrompt: @"OK"];
    
    
    
    [panel beginSheetForDirectory: nil
     
     
                             file: nil
                            types: nil//[NSArray arrayWithObject: @"zip"] // 文件类型
                   modalForWindow: _window
     
     
                    modalDelegate: self
                   didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                      contextInfo: nil];
    
    
    //NSString *test = @"hellosss";
    //[_lblSHA1 setStringValue:test.MD5];
    
    
}


- (IBAction)btnCalc:(id)sender {
    
    NSString *selvalue = [_cmbTypeC stringValue];
    
    if([selvalue isEqualToString:@"MD5"])
    {
        CocoaSecurityResult *md5 = [CocoaSecurity md5:_txtString.stringValue];
        //-----md5 begin here ------------------
        NSString *resultc_md5 = md5.hex;
        [_txtResultC setStringValue:resultc_md5];
        
        //-----md5 end here
    }
    else if ([selvalue isEqualToString:@"SHA1"])
    {
        //-----sha1 begin here ------------------
        CocoaSecurityResult *sha1 = [CocoaSecurity sha1:_txtString.stringValue];
        NSString *resultc_sha1 = sha1.hexLower;
        [_txtResultC setStringValue:resultc_sha1];
        //-----sha1 end here
    }
    else if ([selvalue isEqualToString:@"SHA256"])
    {
        //-----sha256 begin here ------------------
        CocoaSecurityResult *sha256 = [CocoaSecurity sha256:_txtString.stringValue];
        NSString *resultc_sha256 = sha256.hexLower;
        [_txtResultC setStringValue:resultc_sha256];
        //-----sha1 end here
    }
    else if ([selvalue isEqualToString:@"SHA512"])
    {
        
        //-----sha512 begin here ------------------
        CocoaSecurityResult *sha512 = [CocoaSecurity sha512:_txtString.stringValue];
        NSString *resultc_sha512 = sha512.hexLower;
        [_txtResultC setStringValue:resultc_sha512];
        //-----sha1 end here
    }
}

- (IBAction)btnCompare:(id)sender {
    
    if([_txtResult.stringValue.lowercaseString isEqualToString:_txtCompare.stringValue.lowercaseString])
    {
        [_txtCompareResult setStringValue:@"Yes,same..."];
    }
    else
    {
        [_txtCompareResult setStringValue:@"No,No..."];
    }
        
}

@end
