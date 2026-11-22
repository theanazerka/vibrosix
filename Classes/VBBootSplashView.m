#import "VBBootSplashView.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface VBBootSplashView () {
    AVAudioPlayer *_chimePlayer;
    UIView *_progressFill;
    UILabel *_statusLabel;
    UIActivityIndicatorView *_spinner;
    CGFloat _trackW;
}
@end

@implementation VBBootSplashView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.84f green:0.84f blue:0.85f alpha:1.0f];
        [self buildClassicMacBootUI];
    }
    return self;
}

- (void)buildClassicMacBootUI {
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat cx = w * 0.5f;

    // Classic Mac OS X boot subtle platinum gray gradient
    CAGradientLayer *bg = [CAGradientLayer layer];
    bg.frame = self.bounds;
    bg.colors = @[
        (id)[UIColor colorWithRed:0.88f green:0.88f blue:0.89f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.81f green:0.81f blue:0.83f alpha:1.0f].CGColor
    ];
    [self.layer insertSublayer:bg atIndex:0];

    // Iconic Mac OS X welcome card frame (subtle brushed white/platinum panel)
    CGFloat cardW = w - 40.0f;
    CGFloat cardH = 266.0f;
    CGFloat cardY = (h - cardH) * 0.45f;

    UIView *card = [[UIView alloc] initWithFrame:CGRectMake((w - cardW) * 0.5f, cardY, cardW, cardH)];
    card.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.96f alpha:0.96f];
    card.layer.cornerRadius = 10.0f;
    card.layer.borderWidth = 1.0f;
    card.layer.borderColor = [UIColor colorWithWhite:0.65f alpha:1.0f].CGColor;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.25f;
    card.layer.shadowRadius = 12.0f;
    card.layer.shadowOffset = CGSizeMake(0, 5);
    [self addSubview:card];

    // Classic Mac OS top subtle pinstripe / brushed title strip inside card
    UIView *topTint = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cardW, 18)];
    topTint.backgroundColor = [UIColor colorWithWhite:0.88f alpha:0.65f];
    topTint.layer.cornerRadius = 10.0f;
    [card addSubview:topTint];

    // Embossed gray/silver vibrator wand emblem (classic gray Apple boot logo vibe)
    UIImage *wandImg = [UIImage imageNamed:@"wand_black"];
    UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake((cardW - 36.0f) * 0.5f, 22.0f, 36.0f, 118.0f)];
    logoView.image = wandImg;
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    logoView.alpha = 0.78f;
    logoView.layer.shadowColor = [UIColor whiteColor].CGColor;
    logoView.layer.shadowOpacity = 0.9f;
    logoView.layer.shadowRadius = 1.0f;
    logoView.layer.shadowOffset = CGSizeMake(0, 1);
    [card addSubview:logoView];

    // Classic "vibratorOS" title in Lucida/Helvetica Neue style
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 146, cardW - 24, 34)];
    title.backgroundColor = [UIColor clearColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.text = @"vibratorOS";
    title.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.0f] ?: [UIFont systemFontOfSize:28.0f];
    title.textColor = [UIColor colorWithWhite:0.20f alpha:1.0f];
    title.shadowColor = [UIColor whiteColor];
    title.shadowOffset = CGSizeMake(0, 1);
    [card addSubview:title];

    // Classic Mac OS X Aqua recessed progress bar
    _trackW = cardW - 52.0f;
    UIView *track = [[UIView alloc] initWithFrame:CGRectMake(26, 192, _trackW, 12)];
    track.backgroundColor = [UIColor colorWithWhite:0.82f alpha:1.0f];
    track.layer.cornerRadius = 6.0f;
    track.layer.borderWidth = 1.0f;
    track.layer.borderColor = [UIColor colorWithWhite:0.58f alpha:1.0f].CGColor;
    track.clipsToBounds = YES;
    [card addSubview:track];

    _progressFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 12)];
    _progressFill.layer.cornerRadius = 5.0f;
    _progressFill.clipsToBounds = YES;
    CAGradientLayer *aqua = [CAGradientLayer layer];
    aqua.frame = CGRectMake(0, 0, _trackW, 12);
    aqua.colors = @[
        (id)[UIColor colorWithRed:0.55f green:0.82f blue:1.00f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.14f green:0.52f blue:0.96f alpha:1.0f].CGColor,
        (id)[UIColor colorWithRed:0.35f green:0.74f blue:1.00f alpha:1.0f].CGColor
    ];
    aqua.locations = @[ @0.0, @0.52, @1.0 ];
    [_progressFill.layer addSublayer:aqua];
    [track addSubview:_progressFill];

    // Boot status text ("Starting vibratorOS...")
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 212, cardW - 32, 18)];
    _statusLabel.backgroundColor = [UIColor clearColor];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.text = @"Starting vibratorOS...";
    _statusLabel.font = [UIFont systemFontOfSize:11.5f];
    _statusLabel.textColor = [UIColor colorWithWhite:0.38f alpha:1.0f];
    [card addSubview:_statusLabel];

    // Iconic gray Mac boot spinning gear below the card
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.center = CGPointMake(cx, CGRectGetMaxY(card.frame) + 28.0f);
    [_spinner startAnimating];
    [self addSubview:_spinner];

    // Subtle copyright line at bottom like classic Mac OS
    UILabel *ver = [[UILabel alloc] initWithFrame:CGRectMake(16, h - 28, w - 32, 16)];
    ver.backgroundColor = [UIColor clearColor];
    ver.textAlignment = NSTextAlignmentCenter;
    ver.text = @"vibratorOS X 10.6 • Version 1.5";
    ver.font = [UIFont systemFontOfSize:10.0f];
    ver.textColor = [UIColor colorWithWhite:0.46f alpha:1.0f];
    [self addSubview:ver];
}

- (void)playStartupChime {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"startup15" ofType:@"mp3"];
    if (!path) return;

    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *err = nil;
    if ([session respondsToSelector:@selector(setCategory:withOptions:error:)]) {
        [session setCategory:AVAudioSessionCategoryPlayback
                 withOptions:AVAudioSessionCategoryOptionMixWithOthers
                       error:&err];
    } else {
        [session setCategory:AVAudioSessionCategoryPlayback error:&err];
    }
    [session setActive:YES error:&err];

    NSURL *url = [NSURL fileURLWithPath:path];
    _chimePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    _chimePlayer.volume = 1.0f;
    [_chimePlayer prepareToPlay];
    [_chimePlayer play];
}

- (void)startBootSequence {
    [self playStartupChime];

    // Stage 1: fill to 65%
    [UIView animateWithDuration:1.35
                          delay:0.10
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self->_progressFill.frame = CGRectMake(0, 0, self->_trackW * 0.68f, 12);
                     }
                     completion:^(BOOL finished) {
                         self->_statusLabel.text = @"Loading ERM-4095 Driver...";
                         // Stage 2: finish bar to 100%
                         [UIView animateWithDuration:0.95
                                               delay:0.05
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              self->_progressFill.frame = CGRectMake(0, 0, self->_trackW, 12);
                                          }
                                          completion:^(BOOL done) {
                                              self->_statusLabel.text = @"Welcome to vibratorOS";
                                              // Smooth crossfade into the app right as chime ends (~2.5s total)
                                              [UIView animateWithDuration:0.38
                                                                    delay:0.18
                                                                  options:UIViewAnimationOptionCurveEaseInOut
                                                               animations:^{
                                                                   self.alpha = 0.0f;
                                                                   self.transform = CGAffineTransformMakeScale(1.04f, 1.04f);
                                                               }
                                                               completion:^(BOOL fin) {
                                                                   [self->_spinner stopAnimating];
                                                                   [self removeFromSuperview];
                                                               }];
                                          }];
                     }];
}

@end
