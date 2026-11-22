#import <UIKit/UIKit.h>

@protocol VBTouchPadViewDelegate <NSObject>
- (void)touchPadDidUpdateActive:(BOOL)active intensity:(float)intensity pulseRate:(float)pulseRate;
@end

@interface VBTouchPadView : UIView
@property (nonatomic, weak) id<VBTouchPadViewDelegate> delegate;
@end
