export THEOS_PACKAGE_SCHEME = rootless
export TARGET = iphone:clang:latest:15.0
export ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk
SUBPROJECTS = proxyctl module app
include $(THEOS_MAKE_PATH)/aggregate.mk
