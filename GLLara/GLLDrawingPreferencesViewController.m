//
//  GLLDrawingPreferencesViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 29.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import "GLLDrawingPreferencesViewController.h"

#import "GLLResourceManager.h"

@interface GLLDrawingPreferencesViewController ()

@property (nonatomic, readwrite, assign) NSUInteger maxAnisotropyLevel;

@end

@implementation GLLDrawingPreferencesViewController

- (id)init {
    if (!(self = [super initWithNibName:@"GLLDrawingPreferencesView" bundle:nil])) {
        return nil;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.maxAnisotropyLevel = [[GLLResourceManager sharedResourceManager] maxAnisotropyLevel];
}

@end
