#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VBPatternType) {
    VBPatternContinuous = 0,
    VBPatternPulse,
    VBPatternWave,
    VBPatternHeartbeat,
    VBPatternTurbo,
    VBPatternCascade,
    VBPatternChaos,
    VBPatternTouchPad
};

extern NSString * const VBEngineStateDidChangeNotification;

@interface VBEngine : NSObject

+ (instancetype)sharedEngine;

@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, assign) VBPatternType pattern;
@property (nonatomic, assign) float intensity;         // 0.1 .. 1.0
@property (nonatomic, assign) float speed;             // 0.2 .. 2.5
@property (nonatomic, assign) BOOL backgroundEnabled;  // Keep alive when locked
@property (nonatomic, assign, readonly) float currentOutputLevel; // 0.0 .. 1.0 for UI
@property (nonatomic, assign, readonly) BOOL usesPrivateAPI;

- (void)start;
- (void)stop;
- (void)toggle;

// Manual TouchPad control (intensity 0..1, pulseRate 0..1 where 1 = continuous)
- (void)updateManualTouchActive:(BOOL)active intensity:(float)intensity pulseRate:(float)pulseRate;

+ (NSString *)nameForPattern:(VBPatternType)pattern;
+ (NSString *)subtitleForPattern:(VBPatternType)pattern;
+ (NSInteger)patternCount;

@end
