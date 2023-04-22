export TARGET = iphone:clang:latest:10.0
export ARCHS = arm64 arm64e
DEBUG = 0
export FINALPACKAGE=0
#CFLAGS = -fobjc-arc  -Wno-error  -Wno-deprecated-declarations

include $(THEOS)/makefiles/common.mk

TOOL_NAME = EZComplete
EZComplete_FILES = OpenAIKeyManager.m EZComplete.m
EZComplete_FRAMEWORKS = UIKit Foundation
EZComplete_CFLAGS += -fobjc-arc  -Wno-error -Wno-deprecated-declarations -Wno-error=unguarded-availability
EZComplete_CODESIGN_FLAGS += -Sent.plist -Icom.i0stweak3r.ezcomplete

include $(THEOS_MAKE_PATH)/tool.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
