#import "VBSkeuoUI.h"
#import <math.h>

@implementation VBSkeuoUI

+ (UIImage *)darkVelvetCaseBackgroundWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();

    // Rich dark plum-charcoal luxury presentation case radial gradient
    NSArray *cols = @[
        (id)[UIColor colorWithRed:0.18f green:0.10f blue:0.17f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.09f green:0.05f blue:0.10f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.03f green:0.02f blue:0.04f alpha:1.0f].CGColor
    ];
    CGFloat locs[] = { 0.0f, 0.52f, 1.0f };
    CGGradientRef g = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)cols, locs);
    CGPoint c = CGPointMake(size.width * 0.5f, size.height * 0.36f);
    CGContextDrawRadialGradient(ctx, g, c, 12.0f, c, size.height * 0.72f, kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(g);

    // Subtle fine leather/velvet micro-grain texture
    srand(4095);
    for (int i = 0; i < 4200; i++) {
        CGFloat x = (CGFloat)(rand() % (int)size.width);
        CGFloat y = (CGFloat)(rand() % (int)size.height);
        BOOL bright = (rand() % 2 == 0);
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:(bright ? 1.0f : 0.0f) alpha:(bright ? 0.035f : 0.08f)].CGColor);
        CGContextFillRect(ctx, CGRectMake(x, y, 1.0f, 1.0f));
    }

    // Subtle quilted diamond stitch lines (very faint luxury velvet case feel)
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.0f alpha:0.16f].CGColor);
    CGContextSetLineWidth(ctx, 1.0f);
    CGFloat step = 44.0f;
    for (CGFloat x = -size.height; x < size.width + size.height; x += step) {
        CGContextMoveToPoint(ctx, x, 0);
        CGContextAddLineToPoint(ctx, x + size.height, size.height);
        CGContextMoveToPoint(ctx, x + size.height, 0);
        CGContextAddLineToPoint(ctx, x, size.height);
    }
    CGContextStrokePath(ctx);

    CGColorSpaceRelease(cs);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (UIImage *)glossyChromeBarWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();

    // Classic iOS 6 split-gloss dark metallic navigation bar
    NSArray *cols = @[
        (id)[UIColor colorWithWhite:0.34f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.19f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.11f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.07f alpha:1.0f].CGColor
    ];
    CGFloat locs[] = { 0.0f, 0.49f, 0.50f, 1.0f };
    CGGradientRef g = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)cols, locs);
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, 0), CGPointMake(0, size.height), 0);
    CGGradientRelease(g);

    // Top 1px chrome highlight & bottom 1px black bevel + subtle drop shadow line
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:1.0f alpha:0.28f].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, size.width, 1));
    CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, size.height - 1, size.width, 1));

    CGColorSpaceRelease(cs);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (UIImage *)glossyPillButtonWithSize:(CGSize)size tint:(UIColor *)tint pressed:(BOOL)pressed {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();

    CGRect r = CGRectInset(CGRectMake(0, 0, size.width, size.height), 0.5f, 0.5f);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:6.0f];

    // Base color
    CGFloat tr = 0.22f, tg = 0.23f, tb = 0.26f, ta = 1.0f;
    if (tint) {
        [tint getRed:&tr green:&tg blue:&tb alpha:&ta];
    }
    if (pressed) {
        tr *= 0.65f; tg *= 0.65f; tb *= 0.65f;
    }

    CGContextSaveGState(ctx);
    [path addClip];

    // Classic iOS 6 split-gloss gradient
    NSArray *cols = @[
        (id)[UIColor colorWithRed:fminf(1, tr * 1.45f) green:fminf(1, tg * 1.45f) blue:fminf(1, tb * 1.45f) alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:tr * 1.05f green:tg * 1.05f blue:tb * 1.05f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:tr * 0.78f green:tg * 0.78f blue:tb * 0.78f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:tr * 0.55f green:tg * 0.55f blue:tb * 0.55f alpha:1.0f].CGColor
    ];
    CGFloat locs[] = { 0.0f, 0.49f, 0.50f, 1.0f };
    CGGradientRef g = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)cols, locs);
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, r.origin.y), CGPointMake(0, CGRectGetMaxY(r)), 0);
    CGGradientRelease(g);

    // Top inner specular highlight
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0f alpha:(pressed ? 0.12f : 0.38f)].CGColor);
    CGContextSetLineWidth(ctx, 1.0f);
    CGContextMoveToPoint(ctx, r.origin.x + 4, r.origin.y + 1.0f);
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(r) - 4, r.origin.y + 1.0f);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);

    // Crisp dark engraved border
    [[UIColor colorWithWhite:0.0f alpha:0.85f] setStroke];
    path.lineWidth = 1.0f;
    [path stroke];

    CGColorSpaceRelease(cs);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (UIImage *)chromeDomeButtonWithSize:(CGSize)size accent:(UIColor *)accent lit:(BOOL)lit pressed:(BOOL)pressed symbol:(NSString *)symbol {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();

    CGFloat d = fminf(size.width, size.height);
    CGPoint c = CGPointMake(size.width * 0.5f, size.height * 0.5f);

    // 1. Recessed silicone socket shadow around chrome ring
    CGRect socket = CGRectMake(c.x - d * 0.5f, c.y - d * 0.5f, d, d);
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.0f alpha:0.65f].CGColor);
    CGContextFillEllipseInRect(ctx, socket);

    // 2. Machined chrome bezel ring
    CGRect bezel = CGRectInset(socket, 1.5f, 1.5f);
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, bezel);
    CGContextClip(ctx);
    NSArray *chCols = @[
        (id)[UIColor colorWithWhite:0.95f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.42f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.78f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.22f alpha:1.0f].CGColor
    ];
    CGGradientRef chG = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)chCols, NULL);
    CGContextDrawLinearGradient(ctx, chG, CGPointMake(bezel.origin.x, bezel.origin.y), CGPointMake(CGRectGetMaxX(bezel), CGRectGetMaxY(bezel)), 0);
    CGGradientRelease(chG);
    CGContextRestoreGState(ctx);

    // 3. Inner glossy glass/metallic dome cap
    CGRect cap = CGRectInset(bezel, 3.0f, 3.0f);
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, cap);
    CGContextClip(ctx);

    CGFloat ar = 1.0f, ag = 0.22f, ab = 0.54f, aa = 1.0f;
    if (accent) [accent getRed:&ar green:&ag blue:&ab alpha:&aa];

    NSArray *capCols;
    if (lit) {
        capCols = @[
            (id)[UIColor colorWithRed:fminf(1, ar + 0.35f) green:fminf(1, ag + 0.35f) blue:fminf(1, ab + 0.35f) alpha:1.0f].CGColor,
            (id)[UIColor colorWithRed:ar green:ag blue:ab alpha:1.0f].CGColor,
            (id)[UIColor colorWithRed:ar * 0.48f green:ag * 0.48f blue:ab * 0.48f alpha:1.0f].CGColor
        ];
    } else if (pressed) {
        capCols = @[
            (id)[UIColor colorWithWhite:0.10f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.22f alpha:1.0f].CGColor
        ];
    } else {
        capCols = @[
            (id)[UIColor colorWithWhite:0.34f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.16f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.07f alpha:1.0f].CGColor
        ];
    }
    CGGradientRef capG = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)capCols, NULL);
    CGContextDrawLinearGradient(ctx, capG, CGPointMake(0, cap.origin.y), CGPointMake(0, CGRectGetMaxY(cap)), 0);
    CGGradientRelease(capG);

    // Classic iOS 6 curved upper-half glass specular highlight
    if (!pressed) {
        CGRect gloss = CGRectMake(cap.origin.x + cap.size.width * 0.14f,
                                  cap.origin.y + 1.5f,
                                  cap.size.width * 0.72f,
                                  cap.size.height * 0.42f);
        NSArray *glCols = @[
            (id)[UIColor colorWithWhite:1.0f alpha:0.60f].CGColor,
            (id)[UIColor colorWithWhite:1.0f alpha:0.05f].CGColor
        ];
        CGContextSaveGState(ctx);
        CGContextAddEllipseInRect(ctx, gloss);
        CGContextClip(ctx);
        CGGradientRef glG = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)glCols, NULL);
        CGContextDrawLinearGradient(ctx, glG, CGPointMake(0, gloss.origin.y), CGPointMake(0, CGRectGetMaxY(gloss)), 0);
        CGGradientRelease(glG);
        CGContextRestoreGState(ctx);
    }
    CGContextRestoreGState(ctx);

    // 4. Crisp engraved / glowing vector symbol (POWER, +, -)
    CGFloat symY = pressed ? 1.0f : 0.0f;
    UIColor *symColor = lit ? [UIColor whiteColor] : [UIColor colorWithWhite:0.92f alpha:1.0f];

    CGContextSaveGState(ctx);
    if (lit) {
        CGContextSetShadowWithColor(ctx, CGSizeZero, 5.0f, [UIColor whiteColor].CGColor);
    } else {
        CGContextSetShadowWithColor(ctx, CGSizeMake(0, -1), 1.0f, [UIColor blackColor].CGColor);
    }
    CGContextSetStrokeColorWithColor(ctx, symColor.CGColor);
    CGContextSetLineCap(ctx, kCGLineCapRound);

    if ([symbol isEqualToString:@"POWER"]) {
        CGFloat pr = cap.size.width * 0.24f;
        CGContextSetLineWidth(ctx, 2.4f);
        // Open ring from -60 deg to +240 deg
        CGContextAddArc(ctx, c.x, c.y + 1.0f + symY, pr, (CGFloat)(-M_PI * 0.28), (CGFloat)(M_PI * 1.28), 0);
        CGContextStrokePath(ctx);
        // Top vertical power stem
        CGContextMoveToPoint(ctx, c.x, c.y - pr - 2.0f + symY);
        CGContextAddLineToPoint(ctx, c.x, c.y - 0.5f + symY);
        CGContextStrokePath(ctx);
    } else if ([symbol isEqualToString:@"+"]) {
        CGFloat arm = cap.size.width * 0.22f;
        CGContextSetLineWidth(ctx, 2.4f);
        CGContextMoveToPoint(ctx, c.x - arm, c.y + symY);
        CGContextAddLineToPoint(ctx, c.x + arm, c.y + symY);
        CGContextMoveToPoint(ctx, c.x, c.y - arm + symY);
        CGContextAddLineToPoint(ctx, c.x, c.y + arm + symY);
        CGContextStrokePath(ctx);
    } else if ([symbol isEqualToString:@"-"]) {
        CGFloat arm = cap.size.width * 0.22f;
        CGContextSetLineWidth(ctx, 2.4f);
        CGContextMoveToPoint(ctx, c.x - arm, c.y + symY);
        CGContextAddLineToPoint(ctx, c.x + arm, c.y + symY);
        CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);

    CGColorSpaceRelease(cs);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (UIImage *)glossyKeycapWithSize:(CGSize)size accent:(UIColor *)accent selected:(BOOL)selected pressed:(BOOL)pressed {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();

    CGRect outer = CGRectMake(0.5f, 0.5f, size.width - 1.0f, size.height - 1.0f);
    UIBezierPath *socketPath = [UIBezierPath bezierPathWithRoundedRect:outer cornerRadius:8.0f];
    [[UIColor colorWithWhite:0.02f alpha:0.96f] setFill];
    [socketPath fill];

    CGFloat inset = pressed ? 2.2f : 1.3f;
    CGRect cap = CGRectInset(outer, inset, inset);
    if (!pressed) cap.size.height -= 1.2f;
    UIBezierPath *capPath = [UIBezierPath bezierPathWithRoundedRect:cap cornerRadius:6.5f];

    CGFloat ar = 1.0f, ag = 0.22f, ab = 0.54f, aa = 1.0f;
    if (accent) [accent getRed:&ar green:&ag blue:&ab alpha:&aa];

    CGContextSaveGState(ctx);
    [capPath addClip];

    NSArray *cols;
    if (selected) {
        cols = @[
            (id)[UIColor colorWithRed:ar * 0.58f green:ag * 0.58f blue:ab * 0.58f alpha:1.0f].CGColor,
            (id)[UIColor colorWithRed:ar * 0.36f green:ag * 0.36f blue:ab * 0.36f alpha:1.0f].CGColor,
            (id)[UIColor colorWithRed:ar * 0.22f green:ag * 0.22f blue:ab * 0.22f alpha:1.0f].CGColor,
            (id)[UIColor colorWithRed:ar * 0.14f green:ag * 0.14f blue:ab * 0.14f alpha:1.0f].CGColor
        ];
    } else if (pressed) {
        cols = @[
            (id)[UIColor colorWithWhite:0.10f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.16f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.18f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.12f alpha:1.0f].CGColor
        ];
    } else {
        cols = @[
            (id)[UIColor colorWithWhite:0.32f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.20f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.14f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.09f alpha:1.0f].CGColor
        ];
    }
    CGFloat locs[] = { 0.0f, 0.48f, 0.50f, 1.0f };
    CGGradientRef g = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)cols, locs);
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, cap.origin.y), CGPointMake(0, CGRectGetMaxY(cap)), 0);
    CGGradientRelease(g);

    // Top chrome edge highlight
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0f alpha:(pressed ? 0.08f : 0.30f)].CGColor);
    CGContextSetLineWidth(ctx, 1.0f);
    CGContextMoveToPoint(ctx, cap.origin.x + 4, cap.origin.y + 0.8f);
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(cap) - 4, cap.origin.y + 0.8f);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);

    // Recessed LED indicator bar near top of keycap
    CGFloat ledW = size.width * 0.44f;
    CGRect ledR = CGRectMake((size.width - ledW) * 0.5f, cap.origin.y + 4.5f, ledW, 3.0f);
    UIBezierPath *ledP = [UIBezierPath bezierPathWithRoundedRect:ledR cornerRadius:1.5f];
    if (selected) {
        CGContextSaveGState(ctx);
        CGContextSetShadowWithColor(ctx, CGSizeZero, 5.0f, accent.CGColor);
        [[UIColor colorWithRed:fminf(1, ar + 0.25f) green:fminf(1, ag + 0.25f) blue:fminf(1, ab + 0.25f) alpha:1.0f] setFill];
        [ledP fill];
        CGContextRestoreGState(ctx);
    } else {
        [[UIColor colorWithWhite:0.05f alpha:0.95f] setFill];
        [ledP fill];
    }

    CGColorSpaceRelease(cs);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (UIImage *)sliderTrackWithHeight:(CGFloat)h fill:(UIColor *)fillColor {
    CGSize sz = CGSizeMake(24.0f, h);
    UIGraphicsBeginImageContextWithOptions(sz, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();

    CGRect r = CGRectMake(0.5f, 0.5f, sz.width - 1.0f, h - 1.0f);
    UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:(h - 1.0f) * 0.5f];
    CGContextSaveGState(ctx);
    [p addClip];

    NSArray *cols;
    if (fillColor) {
        CGFloat fr = 1, fg = 0.2f, fb = 0.5f, fa = 1;
        [fillColor getRed:&fr green:&fg blue:&fb alpha:&fa];
        cols = @[
            (id)[UIColor colorWithRed:fr * 0.55f green:fg * 0.55f blue:fb * 0.55f alpha:1.0f].CGColor,
            (id)[UIColor colorWithRed:fr green:fg blue:fb alpha:1.0f].CGColor,
            (id)[UIColor colorWithRed:fminf(1, fr + 0.25f) green:fminf(1, fg + 0.25f) blue:fminf(1, fb + 0.25f) alpha:1.0f].CGColor
        ];
    } else {
        cols = @[
            (id)[UIColor colorWithWhite:0.04f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.14f alpha:1.0f].CGColor,
            (id)[UIColor colorWithWhite:0.22f alpha:1.0f].CGColor
        ];
    }
    CGGradientRef g = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)cols, NULL);
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, r.origin.y), CGPointMake(0, CGRectGetMaxY(r)), 0);
    CGGradientRelease(g);
    CGContextRestoreGState(ctx);

    [[UIColor colorWithWhite:0.0f alpha:0.85f] setStroke];
    p.lineWidth = 1.0f;
    [p stroke];

    CGColorSpaceRelease(cs);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
}

+ (UIImage *)chromeSliderThumbWithDiameter:(CGFloat)d {
    CGSize sz = CGSizeMake(d + 4, d + 4);
    UIGraphicsBeginImageContextWithOptions(sz, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();

    CGRect r = CGRectMake(2, 1.5f, d, d);

    // Drop shadow
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1.5f), 2.5f, [UIColor colorWithWhite:0.0f alpha:0.75f].CGColor);
    [[UIColor whiteColor] setFill];
    CGContextFillEllipseInRect(ctx, r);
    CGContextRestoreGState(ctx);

    // Brushed chrome disc
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, r);
    CGContextClip(ctx);
    NSArray *cols = @[
        (id)[UIColor colorWithWhite:0.98f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.70f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.86f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.52f alpha:1.0f].CGColor
    ];
    CGGradientRef g = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)cols, NULL);
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, r.origin.y), CGPointMake(0, CGRectGetMaxY(r)), 0);
    CGGradientRelease(g);
    CGContextRestoreGState(ctx);

    // Subtle concave inner dimple
    CGRect dimple = CGRectInset(r, 4.5f, 4.5f);
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, dimple);
    CGContextClip(ctx);
    NSArray *dCols = @[
        (id)[UIColor colorWithWhite:0.58f alpha:1.0f].CGColor,
        (id)[UIColor colorWithWhite:0.92f alpha:1.0f].CGColor
    ];
    CGGradientRef dg = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)dCols, NULL);
    CGContextDrawLinearGradient(ctx, dg, CGPointMake(0, dimple.origin.y), CGPointMake(0, CGRectGetMaxY(dimple)), 0);
    CGGradientRelease(dg);
    CGContextRestoreGState(ctx);

    [[UIColor colorWithWhite:0.15f alpha:0.85f] setStroke];
    CGContextSetLineWidth(ctx, 0.8f);
    CGContextStrokeEllipseInRect(ctx, r);

    CGColorSpaceRelease(cs);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
