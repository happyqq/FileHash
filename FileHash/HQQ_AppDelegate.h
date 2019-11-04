//
//  HQQ_AppDelegate.h
//  FileHash
//
//  Created by 黄启清 on 13-11-14.
//  Copyright (c) 2013年 黄启清. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface HQQ_AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (assign) IBOutlet WebView *web;
- (IBAction)saveAction:(id)sender;
@property (assign) IBOutlet NSTextField *txtFilePath;

@property (weak) IBOutlet NSComboBox *cmbType;
@property (weak) IBOutlet NSTextField *txtResult;

@property (weak) IBOutlet NSTextField *txtCompare;
@property (weak) IBOutlet NSTextField *txtString;
@property (weak) IBOutlet NSComboBox *cmbTypeC;
@property (weak) IBOutlet NSTextField *txtResultC;
@property (weak) IBOutlet NSTextField *txtCompareResult;


- (IBAction)btnSelect:(id)sender;
- (IBAction)btnCalc:(id)sender;
- (IBAction)btnCompare:(id)sender;

@end
