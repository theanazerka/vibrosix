#import "VBTouchPadView.h"
#import <QuartzCore/QuartzCore.h>

@interface VBTouchPadView () {
    BOOL _touching;
    CGPoint _touchPoint;
    float _currentIntensity;
    float _currentRate;
}
@end

@implementation VBTouchPadView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.10f alpha:1.0f];
        self.layer.cornerRadius = 12.0f;
        self.layer.borderWidth = 1.5f;
        self.layer.borderColor = [UIColor colorWithRed:0.85f green:0.18f blue:0.40f alpha:0.65f].CGColor;
        self.clipsToBounds = YES;
        self.multipleTouchEnabled = NO;
    }
    return self;
}

- (void)handleTouch:(UITouch *)touch active:(BOOL)active {
    _touching = active;
    if (active && touch) {
        CGPoint pt = [touch locationInView:self];
        pt.x = fmaxf(0.0f, fminf(self.bounds.size.width, pt.x));
        pt.y = fmaxf(0.0f, fminf(self.bounds.size.height, pt.y));
        _touchPoint = pt;
        _currentIntensity = 1.0f - (pt.y / fmaxf(1.0f, self.bounds.size.height));
        _currentRate = pt.x / fmaxf(1.0f, self.bounds.size.width);
    } else {
        _currentIntensity = 0.0f;
        _currentRate = 0.0f;
    }
    [self.delegate touchPadDidUpdateActive:_touching intensity:_currentIntensity pulseRate:_currentRate];
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouch:[touches anyObject] active:YES];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouch:[touches anyObject] active:YES];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouch:nil active:NO];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouch:nil active:NO];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat w = rect.size.width;
    CGFloat h = rect.size.height;

    // Grid
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.22f alpha:0.45f].CGColor);
    CGContextSetLineWidth(ctx, 0.5f);
    for (int i = 1; i < 6; i++) {
        CGFloat x = w * (i / 6.0f);
        CGContextMoveToPoint(ctx, x, 0);
        CGContextAddLineToPoint(ctx, x, h);
    }
    for (int i = 1; i < 4; i++) {
        CGFloat y = h * (i / 4.0f);
        CGContextMoveToPoint(ctx, 0, y);
        CGContextAddLineToPoint(ctx, w, y);
    }
    CGContextStrokePath(ctx);

    // Axis hints
    UIFont *hintFont = [UIFont boldSystemFontOfSize:10.0f];
    [[UIColor colorWithWhite:0.55f alpha:0.8f] setFill];
    [@"↑ МОЩНОСТЬ" drawAtPoint:CGPointMake(8, 6) withFont:hintFont];
    [@"ЧАСТОТА →" drawAtPoint:CGPointMake(w - 68, h - 18) withFont:hintFont];

    if (_touching) {
        // Crosshair
        CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:1.0f green:0.22f blue:0.46f alpha:0.65f].CGColor);
        CGContextSetLineWidth(ctx, 1.0f);
        CGContextMoveToPoint(ctx, _touchPoint.x, 0);
        CGContextAddLineToPoint(ctx, _touchPoint.x, h);
        CGContextMoveToPoint(ctx, 0, _touchPoint.y);
        CGContextAddLineToPoint(ctx, w, _touchPoint.y);
        CGContextStrokePath(ctx);

        // Glowing touch circle
        CGFloat radius = 16.0f + _currentIntensity * 22.0f;
        CGRect outer = CGRectMake(_touchPoint.x - radius, _touchPoint.y - radius, radius * 2, radius * 2);
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:1.0f green:0.18f blue:0.45f alpha:0.32f].CGColor);
        CGContextFillEllipseInRect(ctx, outer);

        CGRect inner = CGRectMake(_touchPoint.x - 10, _touchPoint.y - 10, 20, 20);
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:1.0f green:0.35f blue:0.55f alpha:0.95f].CGColor);
        CGContextFillEllipseInRect(ctx, inner);

        NSString *hud = [NSString stringWithFormat:@"%d%%  |  %@",
                         (int)(_currentIntensity * 100),
                         _currentRate > 0.85f ? @"МАКС" : [NSString stringWithFormat:@"%d Гц", (int)(2 + _currentRate * 10)]];
        [[UIColor whiteColor] setFill];
        [hud drawAtPoint:CGPointMake(w - 92, 6) withFont:[UIFont boldSystemFontOfSize:11.0f]];
    } else {
        NSString *prompt = @"ВОДИ ПАЛЬЦЕМ ПО ЭКРАНУ";
        UIFont *pFont = [UIFont boldSystemFontOfSize:13.0f];
        CGSize sz = [prompt sizeWithFont:pFont];
        [[UIColor colorWithWhite:0.45f alpha:0.9f] setFill];
        [prompt drawAtPoint:CGPointMake((w - sz.width) * 0.5f, (h - sz.height) * 0.5f) withFont:pFont];
    }
}

@end
