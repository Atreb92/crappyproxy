TOOL_NAME = proxyctl
proxyctl_FILES = main.m
proxyctl_FRAMEWORKS = SystemConfiguration
proxyctl_INSTALL_PATH = /usr/bin
proxyctl_CODESIGN_FLAGS = -Sent.plist
ifneq ($(FINALPACKAGE),1)
proxyctl_CFLAGS += -DPROXYCTL_DEBUG
endif
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tool.mk
