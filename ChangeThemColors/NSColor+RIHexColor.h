//
//  NSColor+RIHexColor.h
//  ChangeThemColors
//
//  Created by Ondrej Rafaj on 12/11/2015.
//  Copyright © 2015 Ridiculous Innovations. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (RIHexColor)

+ (NSColor *)colorFromHexCode:(NSString *)hexCode withAlpha:(CGFloat)alpha;


@end
