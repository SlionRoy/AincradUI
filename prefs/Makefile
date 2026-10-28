TARGET := iphone:clang:latest:16.0
ARCHS := arm64
THEOS_PACKAGE_SCHEME := rootless
include $(THEOS)/makefiles/common.mk
BUNDLE_NAME := AincradUIPrefs
AincradUIPrefs_FILES := AIPRootListController.m AIPAppListController.m
AincradUIPrefs_FRAMEWORKS := UIKit
AincradUIPrefs_LDFLAGS += -Wl,-undefined,dynamic_lookup
AincradUIPrefs_INSTALL_PATH := /Library/PreferenceBundles
AincradUIPrefs_CFLAGS := -fobjc-arc
include $(THEOS_MAKE_PATH)/bundle.mk
