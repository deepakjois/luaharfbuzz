PKGS = harfbuzz

# override CFLAGS+= -fpic -O0 -g `pkg-config --cflags $(PKGS)` 
override CFLAGS+= -O2 -fpic -std=c99 `pkg-config --cflags $(PKGS)` 
ifdef LUA_INCDIR
	LUA_INC = -I $(LUA_INCDIR)
else
	LUA_INC=`pkg-config --cflags lua`
endif

LDFLAGS = -g  -O3 -Wall `pkg-config --libs $(PKGS)` 

# Guide to building Lua Modules: http://lua-users.org/wiki/BuildingModules
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    LIBFLAGS = -shared
endif
ifeq ($(UNAME_S),Darwin)
    LIBFLAGS = -bundle -undefined dynamic_lookup -all_load
endif

# For compatibility with Luarocks
INST_PREFIX = /usr/local
INST_LIBDIR = $(INST_PREFIX)/lib/lua/5.2
INST_LUADIR = $(INST_PREFIX)/share/lua/5.2

DOCS_DIR := docs
BUILD_DIR := build
C_SRC_ROOT := src/luaharfbuzz
SOURCES := luaharfbuzz.c blob.c face.c font.c buffer.c feature.c class_utils.c
OBJECTS := $(SOURCES:%.c=$(BUILD_DIR)/%.o)

all: dirs luaharfbuzz.so

luaharfbuzz.so: $(OBJECTS)
	$(CC) $(LDFLAGS) $(LIBFLAGS) $(OBJECTS) -o $@

$(BUILD_DIR)/%.o: $(C_SRC_ROOT)/%.c
	$(CC) $(CFLAGS) $(LUA_INC) -o $@ -c $<

dirs: ${BUILD_DIR}

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}

spec: all
	busted .

clean:
	rm -rf build *.so

lint:
	luacheck src spec examples

doc:
	ldoc -d ${DOCS_DIR}  .

# For use with Luarocks
install: luaharfbuzz.so src/harfbuzz.lua
	cp luaharfbuzz.so $(INST_LIBDIR)
	cp src/harfbuzz.lua $(INST_LUADIR)

.PHONY: all clean test dirs install lint spec doc
