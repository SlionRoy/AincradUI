TARGET := iphone:clang:latest:16.0
ARCHS := arm64
THEOS_PACKAGE_SCHEME := rootless
INSTALL_TARGET_PROCESSES := SpringBoard
include $(THEOS)/makefiles/common.mk
TWEAK_NAME := AincradUI AincradAppLandscape
AincradUI_FILES := Tweak.xm
AincradUI_CFLAGS := -fobjc-arc
AincradUI_FRAMEWORKS := UIKit Foundation
AincradAppLandscape_FILES := AppLandscape.xm
AincradAppLandscape_CFLAGS := -fobjc-arc
AincradAppLandscape_FRAMEWORKS := UIKit Foundation
SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
