#import "VBEngine.h"
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <dlfcn.h>
#import <math.h>

NSString * const VBEngineStateDidChangeNotification = @"VBEngineStateDidChangeNotification";

typedef void (*VBPlayVibeFunc)(uint32_t inSystemSoundID, void *arg, CFDictionaryRef vibratePattern);
typedef void (*VBStopSoundFunc)(uint32_t inSystemSoundID);

static const uint32_t kVBVibrateSoundID = 4095; // kSystemSoundID_Vibrate

@interface VBEngine () {
    VBPlayVibeFunc _playWithVibe;
    VBStopSoundFunc _stopSound;
    NSTimer *_stepTimer;
    NSTimer *_visualTimer;
    AVAudioPlayer *_silentPlayer;
    NSUInteger _stepIndex;
    float _wavePhase;
    BOOL _manualActive;
    float _manualIntensity;
    float _manualPulseRate;
    BOOL _motorOn;
    float _targetOutputLevel;
}
@property (nonatomic, assign, readwrite) BOOL isRunning;
@property (nonatomic, assign, readwrite) float currentOutputLevel;
@property (nonatomic, assign, readwrite) BOOL usesPrivateAPI;
@end

@implementation VBEngine

+ (instancetype)sharedEngine {
    static VBEngine *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VBEngine alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _playWithVibe = (VBPlayVibeFunc)dlsym(RTLD_DEFAULT, "AudioServicesPlaySystemSoundWithVibration");
        _stopSound = (VBStopSoundFunc)dlsym(RTLD_DEFAULT, "AudioServicesStopSystemSound");
        _usesPrivateAPI = (_playWithVibe != NULL);

        _pattern = VBPatternContinuous;
        _intensity = 1.0f;
        _speed = 1.0f;
        _backgroundEnabled = NO;
        _currentOutputLevel = 0.0f;
        _targetOutputLevel = 0.0f;
    }
    return self;
}

+ (NSInteger)patternCount {
    return 8;
}

+ (NSString *)nameForPattern:(VBPatternType)pattern {
    switch (pattern) {
        case VBPatternContinuous: return @"МАКС";
        case VBPatternPulse:      return @"ПУЛЬС";
        case VBPatternWave:       return @"ВОЛНА";
        case VBPatternHeartbeat:  return @"СЕРДЦЕ";
        case VBPatternTurbo:      return @"ТУРБО";
        case VBPatternCascade:    return @"КАСКАД";
        case VBPatternChaos:      return @"ХАОС";
        case VBPatternTouchPad:   return @"ТАЧПАД";
        default:                  return @"МАКС";
    }
}

+ (NSString *)subtitleForPattern:(VBPatternType)pattern {
    switch (pattern) {
        case VBPatternContinuous: return @"Непрерывная тяга без пауз";
        case VBPatternPulse:      return @"Чёткий ритмичный пульс";
        case VBPatternWave:       return @"Плавные накаты по синусоиде";
        case VBPatternHeartbeat:  return @"Двойной удар тук-тук";
        case VBPatternTurbo:      return @"Ультрабыстрый отбойник";
        case VBPatternCascade:    return @"Разгон от медленного к макс.";
        case VBPatternChaos:      return @"Непредсказуемый рваный ритм";
        case VBPatternTouchPad:   return @"Ручное управление пальцем";
        default:                  return @"";
    }
}

#pragma mark - Background Keep-Alive Audio

- (NSData *)createSilentWAVData {
    // 1 second of 8000 Hz, 16-bit mono PCM silence
    uint32_t sampleRate = 8000;
    uint16_t channels = 1;
    uint16_t bitsPerSample = 16;
    uint32_t dataSize = sampleRate * channels * (bitsPerSample / 8);
    uint32_t chunkSize = 36 + dataSize;
    uint32_t byteRate = sampleRate * channels * (bitsPerSample / 8);
    uint16_t blockAlign = channels * (bitsPerSample / 8);

    NSMutableData *wav = [NSMutableData dataWithCapacity:44 + dataSize];
    [wav appendBytes:"RIFF" length:4];
    [wav appendBytes:&chunkSize length:4];
    [wav appendBytes:"WAVE" length:4];
    [wav appendBytes:"fmt " length:4];
    uint32_t subchunk1Size = 16;
    uint16_t audioFormat = 1; // PCM
    [wav appendBytes:&subchunk1Size length:4];
    [wav appendBytes:&audioFormat length:2];
    [wav appendBytes:&channels length:2];
    [wav appendBytes:&sampleRate length:4];
    [wav appendBytes:&byteRate length:4];
    [wav appendBytes:&blockAlign length:2];
    [wav appendBytes:&bitsPerSample length:2];
    [wav appendBytes:"data" length:4];
    [wav appendBytes:&dataSize length:4];
    [wav increaseLengthBy:dataSize]; // zero-filled silence
    return wav;
}

- (void)startSilentAudio {
    if (!self.backgroundEnabled) return;
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

    if (!_silentPlayer) {
        NSData *wav = [self createSilentWAVData];
        _silentPlayer = [[AVAudioPlayer alloc] initWithData:wav error:&err];
        _silentPlayer.numberOfLoops = -1;
        _silentPlayer.volume = 0.0f;
    }
    [_silentPlayer play];
}

- (void)stopSilentAudio {
    if (_silentPlayer && _silentPlayer.isPlaying) {
        [_silentPlayer stop];
    }
}

#pragma mark - Low-Level Motor Control

- (void)fireMotorForMilliseconds:(NSInteger)durationMs intensity:(float)level {
    float clamped = fmaxf(0.05f, fminf(1.0f, level));
    if (durationMs < 25) durationMs = 25;

    if (_playWithVibe) {
        if (_stopSound) {
            _stopSound(kVBVibrateSoundID);
        }
        NSArray *arr = @[ @YES, @(durationMs), @NO, @10 ];
        NSDictionary *dict = @{
            @"VibePattern": arr,
            @"Intensity": @(clamped)
        };
        _playWithVibe(kVBVibrateSoundID, NULL, (__bridge CFDictionaryRef)dict);
    } else {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    _motorOn = YES;
    _targetOutputLevel = clamped;
}

- (void)haltMotor {
    if (_stopSound) {
        _stopSound(kVBVibrateSoundID);
    }
    _motorOn = NO;
    _targetOutputLevel = 0.0f;
}

#pragma mark - Lifecycle

- (void)setPattern:(VBPatternType)pattern {
    if (_pattern == pattern) return;
    _pattern = pattern;
    _stepIndex = 0;
    _wavePhase = 0.0f;
    if (_pattern == VBPatternTouchPad) {
        [self stop];
    } else if (self.isRunning) {
        [self scheduleNextStepImmediately];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VBEngineStateDidChangeNotification object:self];
}

- (void)setIntensity:(float)intensity {
    _intensity = fmaxf(0.1f, fminf(1.0f, intensity));
    if (self.isRunning && _pattern == VBPatternContinuous) {
        [self scheduleNextStepImmediately];
    }
}

- (void)setSpeed:(float)speed {
    _speed = fmaxf(0.25f, fminf(2.5f, speed));
}

- (void)setBackgroundEnabled:(BOOL)backgroundEnabled {
    _backgroundEnabled = backgroundEnabled;
    if (self.isRunning) {
        if (backgroundEnabled) {
            [self startSilentAudio];
        } else {
            [self stopSilentAudio];
        }
    }
}

- (void)start {
    if (_pattern == VBPatternTouchPad) return;
    if (self.isRunning) return;

    self.isRunning = YES;
    _stepIndex = 0;
    _wavePhase = 0.0f;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [self startSilentAudio];
    [self startVisualTimer];
    [self scheduleNextStepImmediately];

    [[NSNotificationCenter defaultCenter] postNotificationName:VBEngineStateDidChangeNotification object:self];
}

- (void)stop {
    [_stepTimer invalidate];
    _stepTimer = nil;
    _manualActive = NO;
    [self haltMotor];
    [self stopSilentAudio];
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    BOOL wasRunning = self.isRunning;
    self.isRunning = NO;
    if (wasRunning) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VBEngineStateDidChangeNotification object:self];
    }
}

- (void)toggle {
    if (self.isRunning) {
        [self stop];
    } else {
        [self start];
    }
}

#pragma mark - TouchPad Manual Mode

- (void)updateManualTouchActive:(BOOL)active intensity:(float)intensity pulseRate:(float)pulseRate {
    _manualIntensity = fmaxf(0.1f, fminf(1.0f, intensity));
    _manualPulseRate = fmaxf(0.0f, fminf(1.0f, pulseRate));

    if (active && !_manualActive) {
        _manualActive = YES;
        self.isRunning = YES;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [self startVisualTimer];
        [self runManualStep];
        [[NSNotificationCenter defaultCenter] postNotificationName:VBEngineStateDidChangeNotification object:self];
    } else if (!active && _manualActive) {
        [self stop];
    }
}

- (void)runManualStep {
    [_stepTimer invalidate];
    _stepTimer = nil;
    if (!_manualActive) return;

    // pulseRate near 1.0 => continuous; lower => pulsing
    if (_manualPulseRate > 0.85f) {
        [self fireMotorForMilliseconds:450 intensity:_manualIntensity];
        [self scheduleTimerWithInterval:0.38 selector:@selector(runManualStep)];
    } else {
        NSTimeInterval period = 0.55 - (_manualPulseRate * 0.44); // 0.55s down to 0.11s
        NSInteger onMs = (NSInteger)(period * 580.0);
        [self fireMotorForMilliseconds:onMs intensity:_manualIntensity];
        [self scheduleTimerWithInterval:period selector:@selector(runManualStep)];
    }
}

#pragma mark - Pattern Sequencer

- (void)scheduleNextStepImmediately {
    [_stepTimer invalidate];
    _stepTimer = nil;
    [self runPatternStep];
}

- (void)scheduleTimerWithInterval:(NSTimeInterval)interval selector:(SEL)sel {
    [_stepTimer invalidate];
    if (interval < 0.05) interval = 0.05;
    _stepTimer = [NSTimer timerWithTimeInterval:interval target:self selector:sel userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_stepTimer forMode:NSRunLoopCommonModes];
}

- (void)runPatternStep {
    if (!self.isRunning || _pattern == VBPatternTouchPad) return;

    float spd = self.speed;
    float baseInt = self.intensity;
    NSTimeInterval nextInterval = 0.5;

    switch (self.pattern) {
        case VBPatternContinuous: {
            // Overlap slightly so motor stays spinning continuously without clicking gaps
            [self fireMotorForMilliseconds:1100 intensity:baseInt];
            nextInterval = 0.92;
            break;
        }
        case VBPatternPulse: {
            BOOL on = (_stepIndex % 2 == 0);
            NSTimeInterval dur = 0.28 / spd;
            if (on) {
                [self fireMotorForMilliseconds:(NSInteger)(dur * 1000.0) intensity:baseInt];
            } else {
                [self haltMotor];
            }
            nextInterval = dur;
            break;
        }
        case VBPatternWave: {
            // Smooth sine intensity modulation
            _wavePhase += 0.35f * spd;
            float s = (sinf(_wavePhase) + 1.0f) * 0.5f; // 0..1
            float lvl = baseInt * (0.18f + 0.82f * s);
            [self fireMotorForMilliseconds:220 intensity:lvl];
            nextInterval = 0.16;
            break;
        }
        case VBPatternHeartbeat: {
            // lub - dub - rest
            NSUInteger phase = _stepIndex % 4;
            if (phase == 0) {
                [self fireMotorForMilliseconds:(NSInteger)(140.0 / spd) intensity:baseInt];
                nextInterval = 0.18 / spd;
            } else if (phase == 1) {
                [self haltMotor];
                nextInterval = 0.11 / spd;
            } else if (phase == 2) {
                [self fireMotorForMilliseconds:(NSInteger)(200.0 / spd) intensity:baseInt * 0.82f];
                nextInterval = 0.24 / spd;
            } else {
                [self haltMotor];
                nextInterval = 0.55 / spd;
            }
            break;
        }
        case VBPatternTurbo: {
            // Rapid fire jackhammer
            BOOL on = (_stepIndex % 2 == 0);
            NSTimeInterval dur = (on ? 0.085 : 0.065) / spd;
            if (on) {
                [self fireMotorForMilliseconds:(NSInteger)(dur * 1000.0) intensity:baseInt];
            } else {
                [self haltMotor];
            }
            nextInterval = dur;
            break;
        }
        case VBPatternCascade: {
            // 10 steps accelerating then brief pause
            NSUInteger cycle = _stepIndex % 12;
            if (cycle < 10) {
                float progress = (float)cycle / 9.0f;
                NSTimeInterval period = (0.42 - 0.32 * progress) / spd;
                float lvl = baseInt * (0.4f + 0.6f * progress);
                [self fireMotorForMilliseconds:(NSInteger)(period * 720.0) intensity:lvl];
                nextInterval = period;
            } else if (cycle == 10) {
                [self fireMotorForMilliseconds:(NSInteger)(600.0 / spd) intensity:baseInt];
                nextInterval = 0.62 / spd;
            } else {
                [self haltMotor];
                nextInterval = 0.35 / spd;
            }
            break;
        }
        case VBPatternChaos: {
            BOOL on = (arc4random_uniform(100) < 72);
            float randDur = (0.07f + (float)arc4random_uniform(360) / 1000.0f) / spd;
            if (on) {
                float randInt = baseInt * (0.35f + 0.65f * ((float)arc4random_uniform(100) / 100.0f));
                [self fireMotorForMilliseconds:(NSInteger)(randDur * 1000.0) intensity:randInt];
            } else {
                [self haltMotor];
            }
            nextInterval = randDur;
            break;
        }
        case VBPatternTouchPad:
            return;
    }

    _stepIndex++;
    [self scheduleTimerWithInterval:nextInterval selector:@selector(runPatternStep)];
}

#pragma mark - Smooth Visual Meter

- (void)startVisualTimer {
    if (_visualTimer) return;
    _visualTimer = [NSTimer timerWithTimeInterval:1.0 / 30.0 target:self selector:@selector(tickVisual) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_visualTimer forMode:NSRunLoopCommonModes];
}

- (void)tickVisual {
    float target = self.isRunning ? _targetOutputLevel : 0.0f;
    _currentOutputLevel += (target - _currentOutputLevel) * 0.35f;
    if (!self.isRunning && _currentOutputLevel < 0.01f) {
        _currentOutputLevel = 0.0f;
        [_visualTimer invalidate];
        _visualTimer = nil;
    }
}

@end
