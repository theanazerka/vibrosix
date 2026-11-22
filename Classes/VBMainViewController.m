#import "VBMainViewController.h"
#import "VBEngine.h"
#import "VBSiliconeWandView.h"
#import "VBTouchPadView.h"
#import "VBSkeuoUI.h"
#import "VBBootSplashView.h"
#import <QuartzCore/QuartzCore.h>

@interface VBMainViewController () <VBTouchPadViewDelegate> {
    UIImageView *_bgImageView;
    VBSiliconeWandView *_wandView;
    VBTouchPadView *_touchPadView;

    UIButton *_colorButton;
    UIButton *_bgButton;
    UIButton *_lockButton;

    // Machined chrome dome buttons mounted right into the silicone handle: (+) / (POWER) / (-)
    UIButton *_plusButton;
    UIButton *_powerButton;
    UIView *_powerGlowRing;
    UIButton *_minusButton;

    // Recessed smoked-glass LCD medallions flanking the wand
    UIView *_leftLCD;
    UILabel *_intensityBigLabel;
    UIView *_rightLCD;
    UILabel *_modeBigLabel;

    UISlider *_speedSlider;
    UILabel *_speedBadge;

    NSMutableArray *_patternButtons;

    UIView *_lockOverlay;
    NSTimer *_uiTimer;
    BOOL _isCompactScreen;
}
@end

@implementation VBMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect bounds = self.view.bounds;
    _isCompactScreen = (bounds.size.height <= 480.0f);

    // Rich dark tufted velvet presentation-case backdrop
    _bgImageView = [[UIImageView alloc] initWithFrame:bounds];
    _bgImageView.image = [VBSkeuoUI darkVelvetCaseBackgroundWithSize:bounds.size];
    _bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_bgImageView];

    [self buildSkeuoTopChromeBar];
    [self buildSiliconeWandAndChromeButtons];
    [self buildSkeuoBottomDeck];
    [self buildLockOverlay];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(engineStateChanged:)
                                                 name:VBEngineStateDidChangeNotification
                                               object:nil];

    _uiTimer = [NSTimer timerWithTimeInterval:1.0 / 30.0
                                       target:self
                                     selector:@selector(tickUI)
                                     userInfo:nil
                                      repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_uiTimer forMode:NSRunLoopCommonModes];

    [self refreshUI];

    // Classic Mac OS "vibratorOS" boot splash + startup chime
    VBBootSplashView *bootSplash = [[VBBootSplashView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:bootSplash];
    [bootSplash startBootSequence];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_uiTimer invalidate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Classic iOS 6 Glossy Chrome Top Bar

- (void)buildSkeuoTopChromeBar {
    CGFloat w = self.view.bounds.size.width;
    CGFloat barH = 40.0f;

    UIImageView *bar = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, w, barH)];
    bar.image = [VBSkeuoUI glossyChromeBarWithSize:CGSizeMake(w, barH)];
    bar.userInteractionEnabled = YES;
    bar.layer.shadowColor = [UIColor blackColor].CGColor;
    bar.layer.shadowOpacity = 0.75f;
    bar.layer.shadowRadius = 4.0f;
    bar.layer.shadowOffset = CGSizeMake(0, 2);
    [self.view addSubview:bar];

    // Letterpress silver title
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(86, 5, w - 190, 30)];
    title.backgroundColor = [UIColor clearColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.text = @"Vibrator 6";
    title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.5f] ?: [UIFont boldSystemFontOfSize:16.5f];
    title.textColor = [UIColor colorWithWhite:0.93f alpha:1.0f];
    title.shadowColor = [UIColor blackColor];
    title.shadowOffset = CGSizeMake(0, -1);
    [bar addSubview:title];

    // Left glossy iOS 6 bar button: Silicone Color
    _colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _colorButton.frame = CGRectMake(8, 6, 74, 28);
    _colorButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.5f];
    _colorButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
    _colorButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [_colorButton setTitle:@"РОЗОВЫЙ" forState:UIControlStateNormal];
    [_colorButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_colorButton addTarget:self action:@selector(cycleSiliconeColor) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:_colorButton];

    // Right glossy iOS 6 bar buttons: ФОН + LOCK
    _bgButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _bgButton.frame = CGRectMake(w - 104, 6, 46, 28);
    _bgButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.5f];
    _bgButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
    _bgButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [_bgButton setTitle:@"ФОН" forState:UIControlStateNormal];
    [_bgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_bgButton addTarget:self action:@selector(toggleBackgroundMode) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:_bgButton];

    _lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _lockButton.frame = CGRectMake(w - 54, 6, 46, 28);
    _lockButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.5f];
    _lockButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
    _lockButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [_lockButton setTitle:@"LOCK" forState:UIControlStateNormal];
    [_lockButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_lockButton setBackgroundImage:[VBSkeuoUI glossyPillButtonWithSize:_lockButton.bounds.size tint:nil pressed:NO] forState:UIControlStateNormal];
    [_lockButton setBackgroundImage:[VBSkeuoUI glossyPillButtonWithSize:_lockButton.bounds.size tint:nil pressed:YES] forState:UIControlStateHighlighted];
    [_lockButton addTarget:self action:@selector(showLockOverlay) forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:_lockButton];
}

#pragma mark - Photorealistic Wand + Recessed Chrome Dome Buttons

- (UIView *)createRecessedLCDWithFrame:(CGRect)frame caption:(NSString *)caption outValueLabel:(UILabel **)outLbl {
    UIView *box = [[UIView alloc] initWithFrame:frame];
    box.backgroundColor = [UIColor colorWithRed:0.04f green:0.04f blue:0.06f alpha:0.90f];
    box.layer.cornerRadius = 8.0f;
    box.layer.borderWidth = 1.2f;
    box.layer.borderColor = [UIColor colorWithWhite:0.30f alpha:0.65f].CGColor;
    box.clipsToBounds = YES;

    // Curved glass reflection over top half of LCD
    UIView *gloss = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height * 0.44f)];
    gloss.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.09f];
    gloss.userInteractionEnabled = NO;
    [box addSubview:gloss];

    UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(4, 5, frame.size.width - 8, 22)];
    val.backgroundColor = [UIColor clearColor];
    val.textAlignment = NSTextAlignmentCenter;
    val.font = [UIFont fontWithName:@"Courier-Bold" size:16.5f] ?: [UIFont boldSystemFontOfSize:16.5f];
    val.textColor = [UIColor whiteColor];
    val.shadowColor = [UIColor blackColor];
    val.shadowOffset = CGSizeMake(0, 1);
    [box addSubview:val];

    UILabel *cap = [[UILabel alloc] initWithFrame:CGRectMake(4, frame.size.height - 16, frame.size.width - 8, 13)];
    cap.backgroundColor = [UIColor clearColor];
    cap.textAlignment = NSTextAlignmentCenter;
    cap.text = caption;
    cap.font = [UIFont boldSystemFontOfSize:8.5f];
    cap.textColor = [UIColor colorWithWhite:0.55f alpha:1.0f];
    [box addSubview:cap];

    *outLbl = val;
    return box;
}

- (void)buildSiliconeWandAndChromeButtons {
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat deckH = _isCompactScreen ? 124.0f : 142.0f;
    CGFloat wandTop = 42.0f;
    CGFloat wandH = fmaxf(260.0f, h - wandTop - deckH - 4.0f);

    _wandView = [[VBSiliconeWandView alloc] initWithFrame:CGRectMake(0, wandTop, w, wandH)];
    [self.view addSubview:_wandView];

    CGFloat cx = w * 0.5f;
    CGFloat spineCenterY = wandTop + wandH * 0.655f;
    CGFloat pSize = _isCompactScreen ? 40.0f : 46.0f;
    CGFloat pmSize = _isCompactScreen ? 28.0f : 32.0f;
    CGFloat gap = _isCompactScreen ? 7.0f : 10.0f;

    // Pulsing backlit halo behind center chrome power dome
    _powerGlowRing = [[UIView alloc] initWithFrame:CGRectMake(cx - pSize * 0.5f - 6, spineCenterY - pSize * 0.5f - 6, pSize + 12, pSize + 12)];
    _powerGlowRing.layer.cornerRadius = (pSize + 12) * 0.5f;
    _powerGlowRing.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.45f];
    _powerGlowRing.alpha = 0.0f;
    _powerGlowRing.userInteractionEnabled = NO;
    [self.view addSubview:_powerGlowRing];

    // Machined Chrome (+) Dome
    _plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _plusButton.frame = CGRectMake(cx - pmSize * 0.5f, spineCenterY - pSize * 0.5f - gap - pmSize, pmSize, pmSize);
    [_plusButton addTarget:self action:@selector(increaseIntensity) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_plusButton];

    // Machined Chrome (POWER) Dome
    _powerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _powerButton.frame = CGRectMake(cx - pSize * 0.5f, spineCenterY - pSize * 0.5f, pSize, pSize);
    [_powerButton addTarget:self action:@selector(powerButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_powerButton];

    // Machined Chrome (-) Dome
    _minusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _minusButton.frame = CGRectMake(cx - pmSize * 0.5f, spineCenterY + pSize * 0.5f + gap, pmSize, pmSize);
    [_minusButton addTarget:self action:@selector(decreaseIntensity) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_minusButton];

    // Recessed smoked-glass LCD displays flanking the wand handle
    CGFloat lcdW = 78.0f;
    CGFloat lcdH = 44.0f;
    UILabel *intLbl = nil;
    _leftLCD = [self createRecessedLCDWithFrame:CGRectMake(12, spineCenterY - lcdH * 0.5f, lcdW, lcdH)
                                        caption:@"МОЩНОСТЬ"
                                  outValueLabel:&intLbl];
    _intensityBigLabel = intLbl;
    [self.view addSubview:_leftLCD];

    UILabel *modLbl = nil;
    _rightLCD = [self createRecessedLCDWithFrame:CGRectMake(w - lcdW - 12, spineCenterY - lcdH * 0.5f, lcdW, lcdH)
                                         caption:@"РЕЖИМ"
                                   outValueLabel:&modLbl];
    _modeBigLabel = modLbl;
    _modeBigLabel.font = [UIFont boldSystemFontOfSize:12.5f];
    [self.view addSubview:_rightLCD];

    // TouchPad overlay (recessed dark glass panel when ТАЧПАД mode is active)
    _touchPadView = [[VBTouchPadView alloc] initWithFrame:CGRectMake(14, 48, w - 28, wandH - 12)];
    _touchPadView.delegate = self;
    _touchPadView.hidden = YES;
    [self.view addSubview:_touchPadView];
}

#pragma mark - Skeuomorphic Recessed Control Deck (Slider + 8 Glossy Keycaps)

- (void)buildSkeuoBottomDeck {
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat btnH = _isCompactScreen ? 38.0f : 44.0f;
    CGFloat gap = 6.0f;
    CGFloat deckH = (_isCompactScreen ? 124.0f : 142.0f);
    CGFloat deckY = h - deckH;

    // Dark beveled metallic/leather bottom control deck
    UIView *deck = [[UIView alloc] initWithFrame:CGRectMake(0, deckY, w, deckH)];
    deck.backgroundColor = [UIColor colorWithRed:0.07f green:0.06f blue:0.08f alpha:0.96f];
    [self.view addSubview:deck];

    // Chrome top divider trim with highlight + shadow
    UIView *trimTop = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 1)];
    trimTop.backgroundColor = [UIColor blackColor];
    [deck addSubview:trimTop];
    UIView *trimHi = [[UIView alloc] initWithFrame:CGRectMake(0, 1, w, 1)];
    trimHi.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.20f];
    [deck addSubview:trimHi];

    // Skeuomorphic iOS 6 Chrome-Thumb Speed Slider
    _speedBadge = [[UILabel alloc] initWithFrame:CGRectMake(12, 8, 82, 20)];
    _speedBadge.backgroundColor = [UIColor clearColor];
    _speedBadge.font = [UIFont boldSystemFontOfSize:10.5f];
    _speedBadge.textColor = [UIColor colorWithWhite:0.82f alpha:1.0f];
    _speedBadge.shadowColor = [UIColor blackColor];
    _speedBadge.shadowOffset = CGSizeMake(0, -1);
    [deck addSubview:_speedBadge];

    _speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(94, 5, w - 106, 26)];
    _speedSlider.minimumValue = 0.25f;
    _speedSlider.maximumValue = 2.50f;
    _speedSlider.value = [VBEngine sharedEngine].speed;
    UIImage *thumb = [VBSkeuoUI chromeSliderThumbWithDiameter:22.0f];
    [_speedSlider setThumbImage:thumb forState:UIControlStateNormal];
    [_speedSlider setThumbImage:thumb forState:UIControlStateHighlighted];
    [_speedSlider setMaximumTrackImage:[VBSkeuoUI sliderTrackWithHeight:10.0f fill:nil] forState:UIControlStateNormal];
    [_speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
    [deck addSubview:_speedSlider];

    // 2x4 Glossy 3D iOS 6 Hardware Keycaps
    CGFloat margin = 10.0f;
    CGFloat gridY = 34.0f;
    CGFloat btnW = (w - margin * 2 - gap * 3) / 4.0f;
    _patternButtons = [NSMutableArray array];

    for (NSInteger i = 0; i < [VBEngine patternCount]; i++) {
        NSInteger row = i / 4;
        NSInteger col = i % 4;
        CGRect f = CGRectMake(margin + col * (btnW + gap),
                              gridY + row * (btnH + gap),
                              btnW,
                              btnH);

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = f;
        btn.tag = i;
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:10.0f];
        btn.titleLabel.shadowColor = [UIColor blackColor];
        btn.titleLabel.shadowOffset = CGSizeMake(0, -1);
        btn.titleEdgeInsets = UIEdgeInsetsMake(6, 0, 0, 0);
        [btn setTitle:[VBEngine nameForPattern:(VBPatternType)i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor colorWithWhite:0.78f alpha:1.0f] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [btn addTarget:self action:@selector(patternButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

        [deck addSubview:btn];
        [_patternButtons addObject:btn];
    }
}

#pragma mark - Lock Overlay

- (void)buildLockOverlay {
    _lockOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
    _lockOverlay.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.90f];
    _lockOverlay.hidden = YES;

    UILabel *lockTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height * 0.32f, self.view.bounds.size.width - 40, 30)];
    lockTitle.backgroundColor = [UIColor clearColor];
    lockTitle.textAlignment = NSTextAlignmentCenter;
    lockTitle.text = @"ЭКРАН ЗАБЛОКИРОВАН";
    lockTitle.font = [UIFont boldSystemFontOfSize:17.0f];
    lockTitle.textColor = [UIColor whiteColor];
    [_lockOverlay addSubview:lockTitle];

    UILabel *lockSub = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height * 0.32f + 34, self.view.bounds.size.width - 40, 36)];
    lockSub.backgroundColor = [UIColor clearColor];
    lockSub.textAlignment = NSTextAlignmentCenter;
    lockSub.numberOfLines = 2;
    lockSub.text = @"Защита от случайных нажатий.\nВибратор продолжает работать.";
    lockSub.font = [UIFont systemFontOfSize:13.0f];
    lockSub.textColor = [UIColor colorWithWhite:0.65f alpha:1.0f];
    [_lockOverlay addSubview:lockSub];

    UIButton *unlockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    unlockBtn.frame = CGRectMake(36, self.view.bounds.size.height * 0.55f, self.view.bounds.size.width - 72, 50);
    unlockBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12.5f];
    unlockBtn.titleLabel.shadowColor = [UIColor blackColor];
    unlockBtn.titleLabel.shadowOffset = CGSizeMake(0, -1);
    [unlockBtn setTitle:@"УДЕРЖИВАЙ 1 СЕК. ДЛЯ СНЯТИЯ" forState:UIControlStateNormal];
    [unlockBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIColor *crimson = [UIColor colorWithRed:0.78f green:0.12f blue:0.36f alpha:1.0f];
    [unlockBtn setBackgroundImage:[VBSkeuoUI glossyPillButtonWithSize:unlockBtn.bounds.size tint:crimson pressed:NO] forState:UIControlStateNormal];
    [unlockBtn setBackgroundImage:[VBSkeuoUI glossyPillButtonWithSize:unlockBtn.bounds.size tint:crimson pressed:YES] forState:UIControlStateHighlighted];

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleUnlockPress:)];
    lp.minimumPressDuration = 1.0;
    [unlockBtn addGestureRecognizer:lp];
    [_lockOverlay addSubview:unlockBtn];

    [self.view addSubview:_lockOverlay];
}

#pragma mark - Actions

- (void)powerButtonTapped {
    if ([VBEngine sharedEngine].pattern == VBPatternTouchPad) {
        [VBEngine sharedEngine].pattern = VBPatternContinuous;
        [[VBEngine sharedEngine] start];
    } else {
        [[VBEngine sharedEngine] toggle];
    }
    [self refreshUI];
}

- (void)increaseIntensity {
    VBEngine *e = [VBEngine sharedEngine];
    e.intensity = fminf(1.0f, e.intensity + 0.10f);
    [self refreshUI];
}

- (void)decreaseIntensity {
    VBEngine *e = [VBEngine sharedEngine];
    e.intensity = fmaxf(0.10f, e.intensity - 0.10f);
    [self refreshUI];
}

- (void)speedChanged:(UISlider *)slider {
    [VBEngine sharedEngine].speed = slider.value;
    _speedBadge.text = [NSString stringWithFormat:@"РИТМ %.2fx", slider.value];
}

- (void)cycleSiliconeColor {
    VBSiliconeColorTheme next = (VBSiliconeColorTheme)((_wandView.colorTheme + 1) % 4);
    _wandView.colorTheme = next;
    NSArray *names = @[ @"РОЗОВЫЙ", @"ФИОЛЕТ", @"ЧЁРНЫЙ", @"МЯТНЫЙ" ];
    [_colorButton setTitle:names[next] forState:UIControlStateNormal];
    [self refreshUI];
}

- (void)patternButtonTapped:(UIButton *)sender {
    VBPatternType selected = (VBPatternType)sender.tag;
    [VBEngine sharedEngine].pattern = selected;
    [self refreshUI];
}

- (void)toggleBackgroundMode {
    VBEngine *engine = [VBEngine sharedEngine];
    engine.backgroundEnabled = !engine.backgroundEnabled;
    [self refreshUI];
}

- (void)showLockOverlay {
    _lockOverlay.alpha = 0.0f;
    _lockOverlay.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self->_lockOverlay.alpha = 1.0f;
    }];
}

- (void)handleUnlockPress:(UILongPressGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.2 animations:^{
            self->_lockOverlay.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self->_lockOverlay.hidden = YES;
        }];
    }
}

- (void)engineStateChanged:(NSNotification *)note {
    [self refreshUI];
}

#pragma mark - VBTouchPadViewDelegate

- (void)touchPadDidUpdateActive:(BOOL)active intensity:(float)intensity pulseRate:(float)pulseRate {
    [[VBEngine sharedEngine] updateManualTouchActive:active intensity:intensity pulseRate:pulseRate];
}

#pragma mark - UI Refresh & Animation

- (UIColor *)themeAccentColor {
    switch (_wandView.colorTheme) {
        case VBSiliconeColorPink:   return [UIColor colorWithRed:0.96f green:0.18f blue:0.50f alpha:1.0f];
        case VBSiliconeColorPurple: return [UIColor colorWithRed:0.64f green:0.24f blue:0.96f alpha:1.0f];
        case VBSiliconeColorBlack:  return [UIColor colorWithRed:0.95f green:0.16f blue:0.38f alpha:1.0f];
        case VBSiliconeColorMint:   return [UIColor colorWithRed:0.12f green:0.80f blue:0.64f alpha:1.0f];
    }
    return [UIColor colorWithRed:0.96f green:0.18f blue:0.50f alpha:1.0f];
}

- (void)refreshUI {
    VBEngine *engine = [VBEngine sharedEngine];
    BOOL running = engine.isRunning;
    BOOL isTouchPad = (engine.pattern == VBPatternTouchPad);
    UIColor *accent = [self themeAccentColor];

    _touchPadView.hidden = !isTouchPad;
    _powerButton.hidden = isTouchPad;
    _powerGlowRing.hidden = isTouchPad;
    _plusButton.hidden = isTouchPad;
    _minusButton.hidden = isTouchPad;
    _leftLCD.hidden = isTouchPad;
    _rightLCD.hidden = isTouchPad;

    // Glossy top bar buttons
    [_colorButton setBackgroundImage:[VBSkeuoUI glossyPillButtonWithSize:_colorButton.bounds.size tint:accent pressed:NO] forState:UIControlStateNormal];
    [_colorButton setBackgroundImage:[VBSkeuoUI glossyPillButtonWithSize:_colorButton.bounds.size tint:accent pressed:YES] forState:UIControlStateHighlighted];

    UIColor *bgTint = engine.backgroundEnabled ? [UIColor colorWithRed:0.12f green:0.48f blue:0.88f alpha:1.0f] : nil;
    [_bgButton setBackgroundImage:[VBSkeuoUI glossyPillButtonWithSize:_bgButton.bounds.size tint:bgTint pressed:NO] forState:UIControlStateNormal];
    [_bgButton setBackgroundImage:[VBSkeuoUI glossyPillButtonWithSize:_bgButton.bounds.size tint:bgTint pressed:YES] forState:UIControlStateHighlighted];

    // Machined chrome dome buttons on silicone handle
    [_powerButton setBackgroundImage:[VBSkeuoUI chromeDomeButtonWithSize:_powerButton.bounds.size accent:accent lit:running pressed:NO symbol:@"POWER"] forState:UIControlStateNormal];
    [_powerButton setBackgroundImage:[VBSkeuoUI chromeDomeButtonWithSize:_powerButton.bounds.size accent:accent lit:running pressed:YES symbol:@"POWER"] forState:UIControlStateHighlighted];
    _powerGlowRing.backgroundColor = [accent colorWithAlphaComponent:0.55f];

    [_plusButton setBackgroundImage:[VBSkeuoUI chromeDomeButtonWithSize:_plusButton.bounds.size accent:accent lit:NO pressed:NO symbol:@"+"] forState:UIControlStateNormal];
    [_plusButton setBackgroundImage:[VBSkeuoUI chromeDomeButtonWithSize:_plusButton.bounds.size accent:accent lit:YES pressed:YES symbol:@"+"] forState:UIControlStateHighlighted];

    [_minusButton setBackgroundImage:[VBSkeuoUI chromeDomeButtonWithSize:_minusButton.bounds.size accent:accent lit:NO pressed:NO symbol:@"-"] forState:UIControlStateNormal];
    [_minusButton setBackgroundImage:[VBSkeuoUI chromeDomeButtonWithSize:_minusButton.bounds.size accent:accent lit:YES pressed:YES symbol:@"-"] forState:UIControlStateHighlighted];

    // LCD readouts
    _intensityBigLabel.text = [NSString stringWithFormat:@"%d%%", (int)roundf(engine.intensity * 100.0f)];
    _intensityBigLabel.textColor = running ? accent : [UIColor colorWithWhite:0.92f alpha:1.0f];
    _modeBigLabel.text = [VBEngine nameForPattern:engine.pattern];
    _modeBigLabel.textColor = running ? [UIColor whiteColor] : [UIColor colorWithWhite:0.85f alpha:1.0f];

    // Skeuomorphic slider track tint
    _speedBadge.text = [NSString stringWithFormat:@"РИТМ %.2fx", engine.speed];
    [_speedSlider setMinimumTrackImage:[VBSkeuoUI sliderTrackWithHeight:10.0f fill:accent] forState:UIControlStateNormal];

    // 3D glossy keycaps with LED slits
    for (UIButton *btn in _patternButtons) {
        BOOL sel = (btn.tag == engine.pattern);
        btn.selected = sel;
        [btn setBackgroundImage:[VBSkeuoUI glossyKeycapWithSize:btn.bounds.size accent:accent selected:NO pressed:NO] forState:UIControlStateNormal];
        [btn setBackgroundImage:[VBSkeuoUI glossyKeycapWithSize:btn.bounds.size accent:accent selected:NO pressed:YES] forState:UIControlStateHighlighted];
        [btn setBackgroundImage:[VBSkeuoUI glossyKeycapWithSize:btn.bounds.size accent:accent selected:YES pressed:NO] forState:UIControlStateSelected];
    }
}

- (void)tickUI {
    VBEngine *engine = [VBEngine sharedEngine];
    float lvl = engine.currentOutputLevel;
    BOOL running = engine.isRunning;

    [_wandView tickWithOutputLevel:lvl active:running];

    if (running && engine.pattern != VBPatternTouchPad) {
        _powerGlowRing.alpha = 0.25f + lvl * 0.65f;
        CGFloat sc = 0.96f + lvl * 0.16f;
        _powerGlowRing.transform = CGAffineTransformMakeScale(sc, sc);
    } else {
        _powerGlowRing.alpha = 0.0f;
        _powerGlowRing.transform = CGAffineTransformIdentity;
    }
}

@end
