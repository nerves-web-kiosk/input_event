# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_LIBDIR path to libei.a
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj

# Check that we're on a supported build platform
ifeq ($(CROSSCOMPILE),)
    # Not crosscompiling, so check that we're on Linux.
    ifneq ($(shell uname -s),Linux)
        $(warning input_event only works on Linux, but crosscompilation)
        $(warning is supported by defining $$CROSSCOMPILE, $$ERL_EI_INCLUDE_DIR,)
        $(warning and $$ERL_EI_LIBDIR. See Makefile for details. If using Nerves,)
        $(warning this should be done automatically.)
        $(warning .)
        $(warning Skipping C compilation unless targets explicitly passed to make.)
	DEFAULT_TARGETS = $(PREFIX)
    endif
endif

DEFAULT_TARGETS ?= $(PREFIX) $(BUILD) $(PREFIX)/input_event

LDFLAGS +=
CFLAGS += -std=gnu99

# Enable for debug messages
#CFLAGS += -DDEBUG

SRC=$(wildcard src/*.c)
OBJ = $(SRC:src/%.c=$(BUILD)/%.o)

calling_from_make:
	mix compile

all: $(DEFAULT_TARGETS)

$(BUILD)/%.o: src/%.c
	@echo " CC $(notdir $@)"
	$(CC) -c $(CFLAGS) -o $@ $<

$(PREFIX) $(BUILD):
	mkdir -p $@

$(PREFIX)/input_event: $(OBJ)
	@echo " LD $(notdir $@)"
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	$(RM) $(PREFIX)/input_event $(BUILD)/*.o

.PHONY: all clean calling_from_make

# Don't echo commands unless the caller exports "V=1"
${V}.SILENT:
