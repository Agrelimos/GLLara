//
//  GLLDocument.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocument.h"

#import "GLLAmbientLight.h"
#import "GLLAngleRangeValueTransformer.h"
#import "GLLCamera.h"
#import "GLLDirectionalLight.h"
#import "GLLDocumentWindowController.h"
#import "GLLItem.h"
#import "GLLLogarithmicValueTransformer.h"
#import "GLLModel.h"
#import "GLLRenderWindowController.h"
#import "TR1Level.h"
#import "TRItemSelectWindowController.h"

@interface GLLDocument ()
{
	GLLDocumentWindowController *documentWindowController;
	TRItemSelectWindowController *itemController;
}

@end

@implementation GLLDocument

+ (void)initialize
{
	[NSValueTransformer setValueTransformer:[[GLLAngleRangeValueTransformer alloc] init] forName:@"GLLAngleRangeValueTransformer"];
	[NSValueTransformer setValueTransformer:[[GLLLogarithmicValueTransformer alloc] init] forName:@"GLLLogarithmicValueTransformer"];
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
	if (!(self = [super initWithType:typeName error:outError]))
		return nil;
	
	[self.managedObjectContext processPendingChanges];
	[self.managedObjectContext.undoManager disableUndoRegistration];
	// Prepare the default lights
	
	// One ambient light
	GLLAmbientLight *ambientLight = [NSEntityDescription insertNewObjectForEntityForName:@"GLLAmbientLight" inManagedObjectContext:self.managedObjectContext];
	ambientLight.color = [NSColor darkGrayColor];
	ambientLight.index = 0;
	
	// Three directional lights.
	for (int i = 0; i < 3; i++)
	{
		GLLDirectionalLight *directionalLight = [NSEntityDescription insertNewObjectForEntityForName:@"GLLDirectionalLight" inManagedObjectContext:self.managedObjectContext];
		directionalLight.isEnabled = (i == 0);
		directionalLight.diffuseColor = [NSColor whiteColor];
		directionalLight.specularColor = [NSColor whiteColor];
		directionalLight.index = i + 1;
	}
	
	// Prepare standard camera
	[NSEntityDescription insertNewObjectForEntityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	
	[self.managedObjectContext processPendingChanges];
	[self.managedObjectContext.undoManager enableUndoRegistration];
	
	return self;
}

- (void)makeWindowControllers
{
	documentWindowController = [[GLLDocumentWindowController alloc] initWithManagedObjectContext:self.managedObjectContext];
	[self addWindowController:documentWindowController];

	NSFetchRequest *camerasFetchRequest = [[NSFetchRequest alloc] init];
	camerasFetchRequest.entity = [NSEntityDescription entityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	camerasFetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	NSArray *cameras = [self.managedObjectContext executeFetchRequest:camerasFetchRequest error:NULL];
	
	for (GLLCamera *camera in cameras)
	{
		GLLRenderWindowController *controller = [[GLLRenderWindowController alloc] initWithCamera:camera];
		[self addWindowController:controller];
	}
}

- (IBAction)openNewRenderView:(id)sender
{
	// 1st: Find an index for the new render view.
	NSFetchRequest *highestIndexRequest = [[NSFetchRequest alloc] init];
	highestIndexRequest.entity = [NSEntityDescription entityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	highestIndexRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:NO] ];
	highestIndexRequest.fetchLimit = 1;
	NSArray *highestCameras = [self.managedObjectContext executeFetchRequest:highestIndexRequest error:NULL];
	NSUInteger index;
	if (highestCameras.count > 0)
		index = [[highestCameras objectAtIndex:0] index] + 1;
	else
		index = 0;
	
	// 2nd: Create that camera object
	GLLCamera *camera = [NSEntityDescription insertNewObjectForEntityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	camera.index = index;
	
	// 3rd: Create its window controller
	GLLRenderWindowController *controller = [[GLLRenderWindowController alloc] initWithCamera:camera];
	[self addWindowController:controller];
	[controller showWindow:sender];
}
- (IBAction)loadMesh:(id)sender;
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.allowedFileTypes = @[ @"net.sourceforge.xnalara.mesh", @"obj", @"com.square-enix.tombraider1234" ];
	[panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
		if (result != NSOKButton) return;
		
		NSString *type = (__bridge_transfer NSString *) UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)panel.URL.pathExtension, kUTTypeData);
		if ([type isEqual:@"com.square-enix.tombraider1234"])
		{
			dispatch_after(1, dispatch_get_current_queue(), ^{
				NSError *error = nil;
				NSData *data = [NSData dataWithContentsOfURL:panel.URL options:0 error:&error];
				if (!data)
				{
					[self.windowForSheet presentError:error];
					return;
				}
				TR1Level *level = [[TR1Level alloc] initWithData:data];
				if (!itemController)
					itemController = [[TRItemSelectWindowController alloc] init];
				itemController.level = level;
				
				[NSApp beginSheet:itemController.window modalForWindow:self.windowForSheet modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
			});
		}
		else
		{
			NSError *error = nil;
			GLLModel *model = [GLLModel cachedModelFromFile:panel.URL error:&error];
			
			if (!model)
			{
				[self.windowForSheet presentError:error];
				return;
			}
			
			GLLItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
			newItem.model = model;
		}
	}];
}

@end
