//
//  NSImage+RIColor.h
//  ChangeThemColors
//
//  Created by Ondrej Rafaj on 12/11/2015.
//  Copyright © 2015 Ridiculous Innovations. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (RIColor)

+ (NSImage *)replaceColor:(NSColor *)color withColor:(NSColor *)newColor inImage:(NSImage *)image useOldAlpha:(BOOL)useAlpha withTolerance:(CGFloat)tolerance;


@end
