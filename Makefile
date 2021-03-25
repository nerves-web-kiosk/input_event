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
	  DEFAULT_TARGETS = priv
    endif
endif

DEFAULT_TARGETS ?= $(PREFIX) $(PREFIX)/input_event

LDFLAGS +=
CFLAGS += -std=gnu99

# Enable for debug messages
#CFLAGS += -DDEBUG

SRC=$(wildcard src/*.c)
OBJ = $(SRC:src/%.c=$(BUILD)/%.o)

calling_from_make:
	mix compile

.PHONY: all clean

all: $(PREFIX) $(BUILD) $(PREFIX)/input_event

$(BUILD)/%.o: src/%.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(PREFIX) $(BUILD):
	mkdir -p $@

$(PREFIX)/input_event: $(OBJ)
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	rm -f $(PREFIX)/input_event $(BUILD)/*.o
