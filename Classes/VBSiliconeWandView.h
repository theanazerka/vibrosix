#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VBSiliconeColorTheme) {
    VBSiliconeColorPink = 0,
    VBSiliconeColorPurple,
    VBSiliconeColorBlack,
    VBSiliconeColorMint
};

@interface VBSiliconeWandView : UIView

@property (nonatomic, assign) VBSiliconeColorTheme colorTheme;
@property (nonatomic, assign) float outputLevel; // 0..1
@property (nonatomic, assign) BOOL active;

- (void)tickWithOutputLevel:(float)level active:(BOOL)active;

@end
