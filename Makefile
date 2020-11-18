###################################################################
# About the driver name and path
###################################################################

# driver library name, without extension
LIB_NAME ?= libusbotghs

# library name, with extension
PROJ_FILES ?= ../../../../

# driver library name, with extension
LIB_FULL_NAME = $(LIB_NAME).a

# SDK helper Makefiles inclusion
-include $(PROJ_FILES)/m_config.mk
-include $(PROJ_FILES)/m_generic.mk

# use an app-specific build dir
APP_BUILD_DIR = $(BUILD_DIR)/drivers/$(LIB_NAME)

###################################################################
# About the compilation flags
###################################################################

CFLAGS += $(DRIVERS_CFLAGS)
CFLAGS += -MMD -MP -O3

#############################################################
# About driver sources
#############################################################

SRC_DIR = .
SRC = $(wildcard $(SRC_DIR)/*.c)
OBJ = $(patsubst %.c,$(APP_BUILD_DIR)/%.o,$(SRC))
DEP = $(OBJ:.o=.d)

OUT_DIRS = $(dir $(OBJ))

# file to (dist)clean
# objects and compilation related
TODEL_CLEAN += $(OBJ)
# targets
TODEL_DISTCLEAN += $(APP_BUILD_DIR)

##########################################################
# generic targets of all libraries makefiles
##########################################################

.PHONY: app doc

default: all

all: $(APP_BUILD_DIR) lib

doc:

show:
	@echo
	@echo "\tAPP_BUILD_DIR\t=> " $(APP_BUILD_DIR)
	@echo
	@echo "C sources files:"
	@echo "\tSRC_DIR\t\t=> " $(SRC_DIR)
	@echo "\tSRC\t\t=> " $(SRC)
	@echo "\tOBJ\t\t=> " $(OBJ)
	@echo

lib: $(APP_BUILD_DIR)/$(LIB_FULL_NAME)

$(APP_BUILD_DIR)/%.o: %.c
	$(call if_changed,cc_o_c)

# lib
$(APP_BUILD_DIR)/$(LIB_FULL_NAME): $(OBJ)
	$(call if_changed,mklib)
	$(call if_changed,ranlib)

$(APP_BUILD_DIR):
	$(call cmd,mkdir)

-include $(DEP)

#####################################################################
# Frama-C
#####################################################################

# This variable is to be overriden by local shell environment variable to
# compile and use frama-C targets
# by default, FRAMAC target is deactivated, it can be activated by overriding
# the following variable value with 'y' in the environment.
FRAMAC_TARGET ?= n

ifeq (y,$(FRAMAC_TARGET))

# some FRAMAC arguments may vary depending on the FRAMA-C version (Calcium, Scandium...)
# Here we support both Calcium (20) and Scandium (21) releases
FRAMAC_VERSION=$(shell frama-c -version|cut -d'.' -f 1)
FRAMAC_RELEASE=$(shell frama-c -version|sed -re 's:^.*\((.*)\)$:\1:g')

#
# INFO: Using Frama-C, the overall flags are not directly used as they are targetting
# arm-none-eabi architecture which is not handled by framaC. Instead, we used
# a 32bits target with custom CFLAGS to handle Frama-C compilation step.
# As a consequence, include paths need to be set here as above CFLAGS are dissmissed.
# Below variables are used to handle Wookey SDK in-tree vs out-of-tree Frama-C compilation,
# which permits to:
# - run Frama-C on an autonomous extract of the overall Wookey firmware, out of the Wookey SDK tree
# - run Frama-C directly in the SDK tree, on the same set of software
# The difference is mostly the dependencies paths. The advantage of such an effort is
# to simplify the begining of the Frama-C integration, by detecting and including the necessary
# dependencies only. In a second step only, the dependencies, if they are anotated or updated,
# are pushed back to their initial position in their initial repositories.
# For libxDCI, the dependencies are:
# - the USB device driver (we have chosen the USB OTG HS (High Speed) driver
# - the libstd, which is the tiny libc implementation of the Wookey environment, including the
#   userspace part of the syscalls.
# - some generated headers associated to the target plateform associated to the driver
# - EwoK kernel exported headers

# This is the device specification header path generated by the Wookey SDK JSON layout.
# The following variable is using the standard Wookey SDK directories structure but
# can be overriden in case of out of tree execution.
# This directory handle both device specifications and devlist header (per device
# unique identifier table).
# INFO: this directory MUST contains a subdir named "generated" which contains these
# two files.
USBOTGHS_DEVHEADER_PATH ?= $(PROJ_FILES)/layouts/boards/wookey

# This is the Wookey micro-libC API directory. This directory is used by all libraries and driver
# and defines all prototypes and C types used nearly everywhere in the Wookey project.
LIBSTD_API_DIR ?= $(PROJ_FILES)/libs/std/api

# This is the EwoK kernel exported headers directory. These headers are requested by the libstd
# itself and thus by upper layers, including drivers and libraries.
EWOK_API_DIR ?= $(PROJ_FILES)/kernel/src/C/exported

LIBUSBCTRL_API_DIR ?= $(PROJ_FILES)/libs/usbctrl/api

SESSION     := framac/results/frama-c-rte-eva-wp-ref.session
EVA_SESSION := framac/results/frama-c-rte-eva.session
TIMESTAMP   := framac/results/timestamp-calcium_wp-eva.txt
EVAREPORT    := framac/results/eva_report_red.txt
JOBS        := $(shell nproc)
# Does this flag could be overriden by env (i.e. using ?=)
TIMEOUT     := 15

FRAMAC_GEN_FLAGS:=\
			-absolute-valid-range 0x40040000-0x40080000 \
			-no-frama-c-stdlib \
	        -warn-left-shift-negative \
	        -warn-right-shift-negative \
	        -warn-signed-downcast \
	        -warn-signed-overflow \
	        -warn-unsigned-downcast \
	        -warn-unsigned-overflow \
	        -warn-invalid-pointer \
			-kernel-msg-key pp \
			-cpp-extra-args="-nostdinc -I framac/include -I api -I $(LIBUSBCTRL_API_DIR) -I $(LIBSTD_API_DIR) -I $(USBOTGHS_DEVHEADER_PATH) -I $(EWOK_API_DIR)"  \
		    -rte \
		    -instantiate

FRAMAC_EVA_FLAGS:=\
		    -eva \
		    -eva-show-perf \
		    -eva-slevel 500 \
			-eva-slevel-function rxflvl_handler:20000 \
			-eva-slevel-function oepint_handler:20000 \
			-eva-slevel-function iepint_handler:20000 \
		    -eva-split-limit 256 \
		    -eva-domains symbolic-locations\
		    -eva-domains equality \
		    -eva-split-return auto \
		    -eva-partition-history 3 \
		    -eva-log a:frama-c-rte-eva.log\
		    -eva-report-red-statuses $(EVAREPORT)


FRAMAC_WP_FLAGS:=\
	        -wp \
		-wp-model "Typed+ref+int" \
		-wp-literals \
		-wp-prover alt-ergo,cvc4,z3 \
		-wp-timeout $(TIMEOUT) \
		-wp-smoke-tests \
		-wp-no-smoke-dead-code \
		-wp-log a:frama-c-rte-eva-wp.log


frama-c-parsing:
	frama-c framac/entrypoint.c usbotghs*.c  \
		 -c11 \
		 -no-frama-c-stdlib \
		 -cpp-extra-args="-nostdinc -I framac/include -I api -I $(LIBUSBCTRL_API_DIR) -I $(LIBSTD_API_DIR) -I $(USBOTGHS_DEVHEADER_PATH) -I $(EWOK_API_DIR)"

frama-c-eva:
	frama-c framac/entrypoint.c usbotghs*.c ulpi.c -c11 \
		    $(FRAMAC_GEN_FLAGS) \
			$(FRAMAC_EVA_FLAGS) \
			-save $(EVA_SESSION)

frama-c:
	frama-c framac/entrypoint.c usbotghs*.c -c11 \
		$(FRAMAC_GEN_FLAGS) \
		$(FRAMAC_EVA_FLAGS) \
		-then \
		$(FRAMAC_WP_FLAGS) \
		-save $(SESSION) \
		-time $(TIMESTAMP)\
		-then -report -report-classify

frama-c-instantiate:
	frama-c framac/entrypoint.c usbotghs*.c ulpi.c -c11 -machdep x86_32 \
			$(FRAMAC_GEN_FLAGS) \
			-instantiate

frama-c-gui:
	frama-c-gui -load $(SESSION)



#
#   			-wp-smoke-tests \
#   			-wp-no-smoke-dead-code \


#    			-then \
#    			-wp-prop=@lemma \
#    			-wp-auto="wp:split,wp:bitrange" \
#  			-wp-auto="wp:bitshift" \

#			-wp-steps 100000 \

#-eva-bitwise-domain
#-eva-slevel-function usbctrl_declare_interface:300000 \
#-eva-equality-through-calls all \
# -from-verify-assigns \
#-eva-use-spec usbotghs_configure \

#   			-wp-smoke-tests \
#   			-wp-smoke-dead-code \
#   			-wp-smoke-dead-call \
#   			-wp-smoke-dead-loop \


# -wp-dynamic         Handle dynamic calls with specific annotations. (set by
#                     default, opposite option is -wp-no-dynamic) (calls = pointeur de fonction, wp a du mal avec cette notion,
#						contrairement à 	eva)

# -wp-init-const      Use initializers for global const variables. (set by
#                     default, opposite option is -wp-no-init-const)

# -wp-split           Split conjunctions into sub-goals. (opposite option is
#                     -wp-no-split)
# -wp-split-depth <p>  Set depth of exploration for splitting conjunctions into
#                     sub-goals.
#                     Value `-1` means an unlimited depth.

# -wp-steps <n>       Set number of steps for provers.

# -wp-let             Use variable elimination. (set by default, opposite
#                     option is -wp-no-let)

# -wp-simpl           Enable Qed Simplifications. (set by default, opposite
#                     option is -wp-no-simpl)

# -wp-par <p>         Number of parallel proof process (default: 4)

# -wp-model <model+...>  Memory model selection. Available selectors:
#                     * 'Hoare' logic variables only
#                     * 'Typed' typed pointers only
#                     * '+nocast' no pointer cast
#                     * '+cast' unsafe pointer casts
#                     * '+raw' no logic variable
#                     * '+ref' by-reference-style pointers detection
#                     * '+nat/+int' natural / machine-integers arithmetics
#                     * '+real/+float' real / IEEE floating point arithmetics

# -wp-literals        Export content of string literals. (opposite option is
#                     -wp-no-literals)

# -eva-bitwise-domain \

endif
