CC_DEFAULT ?= wcc
AS_DEFAULT ?= wasm
LD_DEFAULT ?= wlink OPTION quiet

include $(MWD)/tc-common.mk

CFLAGS += -0 -bt=dos -ms -s -osh -zu -fr=$(basename $@).err
ASFLAGS +=
LDFLAGS += SYSTEM dos
ifneq ($(FUJINET_LIB),__UNDEFINED__)
  LDFLAGS += LIBPATH $(FUJINET_LIB_DIR)
endif

CFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\"

define include-dir-flag
  -I$1
endef

define asm-include-dir-flag
  -I$1
endef

define library-dir-flag
endef

define library-flag
  $1
endef

define link-lib
  $(LIB) -n $1 $2
endef

define link-bin
  $(LD) $(LDFLAGS) \
    disable 1014 \
    name $1 \
    file {$2} \
$(if $(filter __UNDEFINED__,$(FUJINET_LIB)),,$(space) library {$(LIBS)} \)
endef

define compile
  $(CC) $(CFLAGS) -ad=$(OBJ_DIR)/$(basename $(notdir $2)).d -fo=$1 $2
endef

define assemble
  $(AS) -c $(ASFLAGS) -fo=$1 $2 2>&1
endef
