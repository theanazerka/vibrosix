#import "VBSiliconeWandView.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface VBSiliconeWandView () {
    UIImageView *_ghostView;
    UIImageView *_wandImageView;
    float _wavePhase;
    CGPoint _baseCenter;
    CGFloat _headCenterY;
}
@end

@implementation VBSiliconeWandView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        _colorTheme = VBSiliconeColorPink;

        // Aspect ratio of wand_*@2x.png is 195 x 720 (~0.271)
        CGFloat imgH = frame.size.height - 16.0f;
        CGFloat imgW = imgH * (195.0f / 720.0f);
        CGRect imgFrame = CGRectMake((frame.size.width - imgW) * 0.5f, 8.0f, imgW, imgH);
        _baseCenter = CGPointMake(CGRectGetMidX(imgFrame), CGRectGetMidY(imgFrame));
        _headCenterY = imgFrame.origin.y + imgH * 0.165f;

        _ghostView = [[UIImageView alloc] initWithFrame:imgFrame];
        _ghostView.contentMode = UIViewContentModeScaleAspectFit;
        _ghostView.alpha = 0.0f;
        [self addSubview:_ghostView];

        _wandImageView = [[UIImageView alloc] initWithFrame:imgFrame];
        _wandImageView.contentMode = UIViewContentModeScaleAspectFit;
        _wandImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        _wandImageView.layer.shadowOpacity = 0.85f;
        _wandImageView.layer.shadowRadius = 14.0f;
        _wandImageView.layer.shadowOffset = CGSizeMake(0, 10);
        [self addSubview:_wandImageView];

        [self updateWandImage];
    }
    return self;
}

- (void)setColorTheme:(VBSiliconeColorTheme)colorTheme {
    _colorTheme = colorTheme;
    [self updateWandImage];
    [self setNeedsDisplay];
}

- (void)updateWandImage {
    NSString *name = @"wand_pink";
    switch (_colorTheme) {
        case VBSiliconeColorPink:   name = @"wand_pink";   break;
        case VBSiliconeColorPurple: name = @"wand_purple"; break;
        case VBSiliconeColorBlack:  name = @"wand_black";  break;
        case VBSiliconeColorMint:   name = @"wand_mint";   break;
    }
    UIImage *img = [UIImage imageNamed:name];
    _wandImageView.image = img;
    _ghostView.image = img;
}

- (UIColor *)glowColor {
    switch (_colorTheme) {
        case VBSiliconeColorPink:   return [UIColor colorWithRed:1.00f green:0.22f blue:0.56f alpha:1.0f];
        case VBSiliconeColorPurple: return [UIColor colorWithRed:0.72f green:0.30f blue:1.00f alpha:1.0f];
        case VBSiliconeColorBlack:  return [UIColor colorWithRed:1.00f green:0.18f blue:0.42f alpha:1.0f];
        case VBSiliconeColorMint:   return [UIColor colorWithRed:0.20f green:0.95f blue:0.76f alpha:1.0f];
    }
    return [UIColor colorWithRed:1.0f green:0.22f blue:0.56f alpha:1.0f];
}

- (void)tickWithOutputLevel:(float)level active:(BOOL)active {
    _outputLevel = level;
    _active = active;

    if (active && level > 0.02f) {
        _wavePhase += 0.14f + level * 0.20f;
        if (_wavePhase > M_PI * 200.0f) _wavePhase -= M_PI * 200.0f;

        float mag = 1.0f + level * 3.6f;
        CGFloat jx = (((float)arc4random_uniform(200) / 100.0f) - 1.0f) * mag;
        CGFloat jy = (((float)arc4random_uniform(200) / 100.0f) - 1.0f) * (mag * 0.45f);
        CGFloat rot = (((float)arc4random_uniform(200) / 100.0f) - 1.0f) * (0.018f * level);

        _wandImageView.center = CGPointMake(_baseCenter.x + jx, _baseCenter.y + jy);
        _wandImageView.transform = CGAffineTransformMakeRotation(rot);

        // Motion-blur ghost split for intense visual buzz feel
        _ghostView.center = CGPointMake(_baseCenter.x - jx * 1.35f, _baseCenter.y - jy * 0.8f);
        _ghostView.transform = CGAffineTransformMakeRotation(-rot * 1.4f);
        _ghostView.alpha = 0.14f + level * 0.24f;
    } else {
        _wandImageView.center = _baseCenter;
        _wandImageView.transform = CGAffineTransformIdentity;
        _ghostView.center = _baseCenter;
        _ghostView.transform = CGAffineTransformIdentity;
        _ghostView.alpha = 0.0f;
    }

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!_active || _outputLevel <= 0.03f) return;

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    UIColor *gl = [self glowColor];
    CGPoint hc = CGPointMake(rect.size.width * 0.5f, _headCenterY);

    // Soft ambient studio aura behind buzzing head
    NSArray *gCols = @[
        (id)[gl colorWithAlphaComponent:(0.42f * _outputLevel)].CGColor,
        (id)[gl colorWithAlphaComponent:0.0f].CGColor
    ];
    CGGradientRef rad = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)gCols, NULL);
    CGContextDrawRadialGradient(ctx, rad, hc, 12.0f, hc, 118.0f, 0);
    CGGradientRelease(rad);

    // 3 concentric expanding acoustic vibration shockwaves
    for (int i = 0; i < 3; i++) {
        float prog = fmodf((_wavePhase * 0.24f) + (float)i / 3.0f, 1.0f);
        CGFloat rx = 44.0f + prog * 88.0f;
        CGFloat ry = 50.0f + prog * 76.0f;
        float alpha = (1.0f - prog) * 0.62f * _outputLevel;
        CGRect r = CGRectMake(hc.x - rx, hc.y - ry, rx * 2.0f, ry * 2.0f);
        CGContextSetStrokeColorWithColor(ctx, [gl colorWithAlphaComponent:alpha].CGColor);
        CGContextSetLineWidth(ctx, 2.4f * (1.0f - prog * 0.55f));
        CGContextStrokeEllipseInRect(ctx, r);
    }

    CGColorSpaceRelease(cs);
}

@end
