 export THEOS_PACKAGE_SCHEME = rootless
TARGET = iphone:clang:latest:15.0 # Rootless usually targets 15.0+
ARCHS = arm64 arm64e
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TOOL_NAME = EZComplete
EZComplete_FILES = OpenAIKeyManager.m EZComplete.m
EZComplete_FRAMEWORKS = UIKit Foundation AVFoundation
# Added AVFoundation above for the speech logic

EZComplete_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error=unguarded-availability
EZComplete_CODESIGN_FLAGS = -Sent.plist -Icom.i0stweak3r.ezcomplete

include $(THEOS_MAKE_PATH)/tool.mk

# No need to kill SpringBoard for a terminal tool
after-install::
	@echo "EZComplete installed to /var/jb/usr/bin/EZComplete"
