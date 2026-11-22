#import <UIKit/UIKit.h>

@interface VBSkeuoUI : NSObject

+ (UIImage *)darkVelvetCaseBackgroundWithSize:(CGSize)size;
+ (UIImage *)glossyChromeBarWithSize:(CGSize)size;
+ (UIImage *)glossyPillButtonWithSize:(CGSize)size tint:(UIColor *)tint pressed:(BOOL)pressed;
+ (UIImage *)chromeDomeButtonWithSize:(CGSize)size accent:(UIColor *)accent lit:(BOOL)lit pressed:(BOOL)pressed symbol:(NSString *)symbol;
+ (UIImage *)glossyKeycapWithSize:(CGSize)size accent:(UIColor *)accent selected:(BOOL)selected pressed:(BOOL)pressed;
+ (UIImage *)sliderTrackWithHeight:(CGFloat)h fill:(UIColor *)fillColor;
+ (UIImage *)chromeSliderThumbWithDiameter:(CGFloat)d;

@end
