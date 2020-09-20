SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables --no-builtin-rules

CC = gcc
CFLAGS = -std=gnu99

# If DEBUG is set, compile with gdb flags
ifdef DEBUG
CFLAGS += -g -ggdb
endif

# Warnings
WARNINGS = -Wall -Wextra -Wpedantic -Wconversion -Wformat=2 -Winit-self \
	-Wmissing-include-dirs -Wformat-nonliteral -Wnested-externs \
	-Wno-unused-parameter -Wold-style-definition -Wredundant-decls -Wshadow \
	-Wstrict-prototypes -Wwrite-strings

# GCC warnings that Clang doesn't provide:
ifeq ($(CC),gcc)
		WARNINGS += -Wjump-misses-init -Wlogical-op
endif

SOURCEDIR = .
SOURCES := $(subst ./,,$(shell find $(SOURCEDIR) -name '*.c'))

H_FILES = $(subst ./,,$(shell find $(SOURCEDIR) -name '*.h'))
_O_FILES = $(SOURCES:%.c=%.o )

BUILD_DIR = target

ANALYSIS_DIR = $(BUILD_DIR)/analysis

O_DIR = $(BUILD_DIR)/obj
O_FILES = $(patsubst %,$(O_DIR)/%,$(_O_FILES))

EXEC = dev-null

LIBRARIES =

$(O_DIR)/%.o: %.c $(H_FILES)
	mkdir -p $(O_DIR)
	$(CC) -fPIC -c -o $@ $< $(CFLAGS) $(WARNINGS)

$(EXEC): $(O_FILES)
	$(CC) -o $(EXEC) $(O_FILES) $(CFLAGS) $(WARNINGS) $(LIBRARIES)


.PHONY: run
run: $(EXEC)
	./$(EXEC)

.PHONY: valgrind
valgrind:
	@command -v valgrind >/dev/null 2>&1 || { echo >&2 "valgrind not found, aborting analyze"; exit 1; }

.PHONY: analyze
analyze: $(EXEC) valgrind
	mkdir -p $(ANALYSIS_DIR)
	valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes --log-file="$(ANALYSIS_DIR)/memcheck.out" ./$(EXEC)
	cat $(ANALYSIS_DIR)/memcheck.out
	valgrind --tool=callgrind --callgrind-out-file="$(ANALYSIS_DIR)/callgrind.out" ./$(EXEC)
	gprof2dot -f callgrind $(ANALYSIS_DIR)/callgrind.out --root=main | dot -Tpng -o $(ANALYSIS_DIR)/callgrind.png

.PHONY: watch
watch:
	@command -v inotifywait >/dev/null 2>&1 || { echo >&2 "inotifywait not found, aborting watch"; exit 1; }
	while true; do \
		clear; \
		make run || true; \
		inotifywait -qre modify .; \
	done

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR) $(EXEC)
