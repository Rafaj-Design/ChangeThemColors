//
//  ViewController.m
//  ChangeThemColors
//
//  Created by Ondrej Rafaj on 12/11/2015.
//  Copyright © 2015 Ridiculous Innovations. All rights reserved.
//

#import "RIHomeViewController.h"
#import "NSImage+RIColor.h"
#import "NSColor+RIHexColor.h"


typedef NS_ENUM(NSInteger, RIFileType) {
    RIFileTypeUnknown,
    RIFileTypeImage,
    RIFileTypeFolder
};


@interface RIHomeViewController ()

@property (nonatomic, weak) IBOutlet NSButton *loadFolderButton;
@property (nonatomic, strong) IBOutlet NSTextView *logTextView;

@property (nonatomic, strong) IBOutlet NSTextField *fromColorField;
@property (nonatomic, strong) IBOutlet NSTextField *toColorField;
@property (nonatomic, strong) IBOutlet NSTextField *toleranceField;

@property (nonatomic, strong) IBOutlet NSButton *useOldAlphaCheckboxButton;
@property (nonatomic, strong) IBOutlet NSButton *overrideCheckboxButton;
@property (nonatomic, strong) IBOutlet NSButton *doCopyAllCheckboxButton;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *destinationPath;
@property (nonatomic, strong) NSMutableArray *imageFilePaths;

@end


@implementation RIHomeViewController


#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark Controls

- (void)enableAllControls:(BOOL)enable {
    [self.fromColorField setEnabled:enable];
    [self.toColorField setEnabled:enable];
    [self.toleranceField setEnabled:enable];
    
    [self.overrideCheckboxButton setEnabled:enable];
    [self.doCopyAllCheckboxButton setEnabled:enable];
    [self.useOldAlphaCheckboxButton setEnabled:enable];
    
    [self.loadFolderButton setEnabled:enable];
}

#pragma mark Actions

- (IBAction)didClickLoadFiles:(NSButton *)sender {
    [self.logTextView setString:@""];
    
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    openPanel.title = @"Choose file(s) to modify";
    openPanel.showsResizeIndicator = YES;
    openPanel.showsHiddenFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.allowsMultipleSelection = YES;
    openPanel.allowedFileTypes = @[@"png"];
    
    __weak typeof(self) weakSelf = self;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            
            NSURL *selection = openPanel.URLs[0];
            weakSelf.path = [selection.path stringByResolvingSymlinksInPath];
            [weakSelf enableAllControls:NO];
            
            if (self.overrideCheckboxButton.state == NSOffState) {
                NSOpenPanel *openPanel = [NSOpenPanel openPanel];
                
                openPanel.title = @"Destination folder";
                openPanel.showsResizeIndicator = YES;
                openPanel.showsHiddenFiles = NO;
                openPanel.canChooseDirectories = YES;
                openPanel.canChooseFiles = NO;
                openPanel.canCreateDirectories = YES;
                openPanel.allowsMultipleSelection = NO;
                
                [openPanel beginWithCompletionHandler:^(NSInteger result) {
                    if (result == NSModalResponseOK) {
                        
                        NSURL *selection = openPanel.URLs[0];
                        weakSelf.destinationPath = [selection.path stringByResolvingSymlinksInPath];
                        
                        [weakSelf beginProcess];
                    }
                }];
            }
            else {
                [weakSelf beginProcess];
            }
        }
    }];
}

- (IBAction)didCheckOverrideOriginals:(NSButton *)sender {
    [self.doCopyAllCheckboxButton setEnabled:!(sender.state == NSOnState)];
}

#pragma mark Process Images

- (void)beginProcess {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self loadAllImages];
        
        for (NSString *path in _imageFilePaths) {
            NSString *result = nil;
            if ([self processImage:path]) {
                result = [NSString stringWithFormat:@"File processed OK: %@", path];
            }
            else {
                result = [NSString stringWithFormat:@"Unable to process file: %@", path];
            }
            [self log:result];
        }
        
        [self log:@"Finished"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self enableAllControls:YES];
        });
    });
}

- (BOOL)processImage:(NSString *)path {
    // TODO: Load checkboxes when process starts
    BOOL overwrite = (self.overrideCheckboxButton.state == NSOnState);
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];\
    
    NSColor *fromColor = [NSColor colorFromHexCode:self.fromColorField.stringValue withAlpha:1];
    NSColor *toColor = [NSColor colorFromHexCode:self.toColorField.stringValue withAlpha:1];
    
    CGFloat tolerance = self.toleranceField.floatValue;
    // TODO: Load checkboxes when process starts
    BOOL useAlpha = (self.useOldAlphaCheckboxButton.state == NSOnState);
    NSImage *newImage = [NSImage replaceColor:fromColor withColor:toColor inImage:image useOldAlpha:useAlpha withTolerance:tolerance];
    
    NSString *newFolder;
    
    if (!overwrite) {
        newFolder = self.destinationPath;
        
        NSString *newPath = [path stringByReplacingOccurrencesOfString:self.path withString:newFolder];
        
        NSMutableArray *newTargetFolderComponents = [[newPath pathComponents] mutableCopy];
        [newTargetFolderComponents removeLastObject];
        
        NSString *newTargetFolder = [newTargetFolderComponents componentsJoinedByString:@"/"];
        
        if (![_fileManager fileExistsAtPath:newTargetFolder]) {
            [_fileManager createDirectoryAtPath:newTargetFolder withIntermediateDirectories:YES attributes:nil error:nil];
        }
        path = newPath;
    }
    
    NSData *imageData = [newImage TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    [imageData writeToFile:path atomically:NO];
    
    return NO;
}

#pragma mark Logging

- (void)log:(NSString *)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *newString = [string stringByAppendingString:@"\n"];
        [self.logTextView setString:[self.logTextView.string stringByAppendingString:newString]];
        [self.logTextView scrollToEndOfDocument:nil];
    });
}

#pragma mark Handling files

- (RIFileType)filetype:(NSString *)path {
    BOOL isDir;
    if ([_fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        if (isDir) {
            return RIFileTypeFolder;
        }
        else {
            if ([[[path pathExtension] lowercaseString] isEqualToString:@"png"]) {
                return RIFileTypeImage;
            }
        }
    }
    return RIFileTypeUnknown;
}

- (void)discoverImages:(NSString *)path {
    NSString *message = [NSString stringWithFormat:@"Loading images from: %@", path];
    [self log:message];
    
    NSArray *files = [_fileManager contentsOfDirectoryAtPath:path error:nil];
    
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.png'"];
    NSArray *pngFiles = [files filteredArrayUsingPredicate:filter];
    
    if (pngFiles.count > 0) {
        if (!self.imageFilePaths) {
            self.imageFilePaths = [NSMutableArray array];
        }
        for (NSString *pngPath in pngFiles) {
            NSString *newPath = [path stringByAppendingPathComponent:pngPath];
            [self.imageFilePaths addObject:newPath];
        }
        
    }
}

- (void)loadAllImages {
    if ([self filetype:self.path] == RIFileTypeFolder) {
        [self loadAllImagesFrom:self.path];
    }
    else {
        // TODO: Handle single image
    }
}

- (void)loadAllImagesFrom:(NSString *)path {
    
    [self discoverImages:path];
    
    NSArray *files = [_fileManager contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString *path in files) {
        NSString *newPath = [self.path stringByAppendingPathComponent:path];
        if ([self filetype:newPath] == RIFileTypeFolder) {
            [self loadAllImagesFrom:newPath];
        }
    }
}


@end
