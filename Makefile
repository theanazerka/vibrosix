TARGET := iphone:clang:6.1:6.0
ARCHS = armv7
DEBUG = 0
FINALPACKAGE = 1
INSTALL_TARGET_PROCESSES = Vibrator6

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Vibrator6

Vibrator6_FILES = main.m $(wildcard Classes/*.m)
Vibrator6_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore AudioToolbox AVFoundation
Vibrator6_CFLAGS = -fobjc-arc -Os -Wno-deprecated-declarations -Wno-objc-missing-property-synthesis -IClasses
Vibrator6_CODESIGN_FLAGS = -Sentitlements.xml

include $(THEOS_MAKE_PATH)/application.mk
