ifeq ($(TARGET),)
TARGET = mame
endif

# set this the operating system you're building for
# (actually you'll probably need your own main makefile anyways)
MAMEOS = rpi

# extension for executables
EXE =

# CPU core include paths
VPATH=src $(wildcard src/cpu/*)

# compiler, linker and utilities
MD = @mkdir
RM = rm -f
CC  = gcc
CPP = g++
AS  = as
LD  = g++
STRIP = strip

EMULATOR = $(TARGET)$(EXE)

DEFS = -DGP2X -DLSB_FIRST -DALIGN_INTS -DALIGN_SHORTS -DINLINE="static __inline" -Dasm="__asm__ __volatile__" -DMAME_UNDERCLOCK -DENABLE_AUTOFIRE -DBIGCASE

DEP_PKGS = 'glib-2.0 sdl alsa egl glesv2'
DEP_CFLAGS = `pkg-config --cflags $(DEP_PKGS)`
DEP_LIBS = `pkg-config --libs $(DEP_PKGS)`

CFLAGS = -fsigned-char $(DEVLIBS) \
	-Isrc -Isrc/$(MAMEOS) -Isrc/zlib \
	-I$(SDKSTAGE)/opt/vc/include -I$(SDKSTAGE)/opt/vc/include/interface/vcos/pthreads \
	-I$(SDKSTAGE)/opt/vc/include/interface/vmcs_host/linux \
	$(DEP_CFLAGS) \
	-mcpu=native -mtune=native -mfloat-abi=hard \
	-O3 -ffast-math -fomit-frame-pointer -fstrict-aliasing \
	-mstructure-size-boundary=32 -fexpensive-optimizations \
	-fweb -frename-registers -falign-functions=16 -falign-loops -falign-labels -falign-jumps \
	-finline -finline-functions -fno-common -fno-builtin -fsingle-precision-constant \
	-Wall -Wno-sign-compare -Wunused -Wpointer-arith -Wcast-align -Waggregate-return -Wshadow

LDFLAGS = $(CFLAGS)

LIBS = -lm -L$(SDKSTAGE)/opt/vc/lib -lbcm_host -lrt $(DEP_LIBS)

OBJ = obj_$(TARGET)_$(MAMEOS)
OBJDIRS = $(OBJ) $(OBJ)/cpu $(OBJ)/sound $(OBJ)/$(MAMEOS) \
	$(OBJ)/drivers $(OBJ)/machine $(OBJ)/vidhrdw $(OBJ)/sndhrdw \
	$(OBJ)/zlib

all:	maketree $(EMULATOR)

# include the various .mak files
include src/core.mak
include src/$(TARGET).mak
include src/rules.mak
include src/sound.mak
include src/$(MAMEOS)/$(MAMEOS).mak

# combine the various definitions to one
CDEFS = $(DEFS) $(COREDEFS) $(CPUDEFS) $(SOUNDDEFS)

$(EMULATOR): $(COREOBJS) $(OSOBJS) $(DRVOBJS)
	@echo Linking $<...
	@$(LD) $(LDFLAGS) $(COREOBJS) $(OSOBJS) $(LIBS) $(DRVOBJS) -o $@
	@$(STRIP) $(EMULATOR)

$(OBJ)/%.o: src/%.c
	@echo Compiling $<...
	@$(CC) $(CDEFS) $(CFLAGS) -c $< -o $@

$(OBJ)/%.o: src/%.cpp
	@echo Compiling $<...
	@$(CPP) $(CDEFS) $(CFLAGS) -std=c++98 -fno-rtti -c $< -o $@

$(OBJ)/%.o: src/%.s
	@echo Compiling $<...
	@$(CPP) $(CDEFS) $(CFLAGS) -c $< -o $@

$(OBJ)/%.o: src/%.S
	@echo Compiling $<...
	@$(CPP) $(CDEFS) $(CFLAGS) -c $< -o $@

$(sort $(OBJDIRS)):
	@$(MD) $@

maketree: $(sort $(OBJDIRS))

install:
	@cp $(EMULATOR) $(DESTDIR)/bin

uninstall:
	@rm $(DESTDIR)/bin$(EMULATOR)

clean:
	@$(RM) -r $(OBJ)
	@$(RM) $(EMULATOR)
