# This Makefile is partially based on "a completely generic Makefile",
# originally created by Justin Husted <husted@cs>
#
# Rewrite and sane dependencies support by Petr Baudis <pasky@ucw.cz>
# Cygwin support and configuration by Jaen Saul <slowbyte@hot.ee>
# A lot of modifications by Bjarni Corfitzen <bjarni@openttd.com>
#
# Last modified by: $Author: strigeus $
# On: $Date: 2004/03/11 19:15:06 $


##############################################################################
#
# Usage
#

# Synopsis:
#
# make WITH_ZLIB=1 UNIX=1 MANUAL_CONFIG=1
#
# (See below for the list of possible options.)
#
# Alternately, you can run make without the MANUAL_CONFIG part. It then
# generates Makefile.config, where you can customize all the options.
# However beware that for all subsequent calls the option values from
# Makefile.config take precedence to the commandline options.
#
# (That means that you probably want to either specify the options on command
# line together with MANUAL_CONFIG=1 or you want to specify no commandline
# options at all.)

# Targets:
#
# Defaults to building binary
# clean: remove intermediate build files
# mrproper: remove intermediate files and makefile configuration
# upgradeconf: add new options to old Makefile.config
# osx: OS X application

# Options:
#
# Summary of OS choice defines
# WIN32: building on Windows
# UNIX: building on *nix derivate (Linux, FreeBSD)
# OSX: building on Mac OS X
# MORPHOS: building on MorphOS
#
# Summary of library choice defines
# WITH_ZLIB: savegames using zlib
# WITH_PNG: screenshots using PNG
# WITH_SDL: SDL video driver support
#
# Summary of other defines:
# MANUAL_CONFIG: do not use Makefile.config, config options set manually
# DEBUG: build in debug mode
# PROFILE: build in profile mode, disables -s and -fomit-frame-pointer
# DISPLAY_WARNINGS: when off, some errors are not displayed while compiling
# TRANSLATOR: build in translator mode (untranslated strings are prepended by
#             a <TODO> mark)
# RELEASE: this will be the released version number. It replaces all places
#          where it normally would print the revision number
# MIDI: if set, it will use it as custom path to midi player.
#  If unset, it will use the hardcoded path in the c code
# NOVERBOSE: supress all warnings and errors during compilation.
#  It looks nicer, but you will not know what went wrong. Use it on released (stable) sources only
#
# Paths:
# INSTALL: If not set, the game uses the directory of the binary to
# store everything (lang, data, gm, save and openttd.cfg), this is the `old' behaviour. 
# In this case, none of the following paths are used, you also should _not_
# use `make install', but copy the required stuff yourself (or just play out
# of you source directory, which should work fine).
# If you want to use `make install' to install the game globally, you should
# define it _before_ you build the game. If you only define INSTALL when you
# do `make install', the game won't be able to find it's files (so you should
# also define all the following paths before building).
#
# So, the following paths should be defined if INSTALL is defined.
# None of these paths have to end with /
# PREFIX:	Normally /usr/local
# BINARY_DIR:	The location of the binary, normally games. (Will be prefixed
#		with $PREFIX)
# DATA_DIR: 	The location of the data (lang, data and gm), normally 
#		share/games/openttd. (Will be prefixed with $PREFIX)
# PERSONAL_DIR:	The directory where openttd.cfg and the save folder will be
#		stored. You cannot use ~ here, define USE_HOMEDIR for that.
# USE_HOMEDIR:	If this variable is set, PERSONAL_DIR will be prefixed with
#		~/ at runtime (the user's homedir)
#
# DEST_DIR:	make install will use this directory instead of the filesystem
# 		root to install its files. This should normally not be used by
# 		ordinary users, currently it is only used for the debian
# 		packaging. This value should only be set when calling `make
# 		install' and is not saved in Makefile.config
#
# STATIC: link statically
# CYGWIN: build in Cygwin environment
# MINGW: build with MingW compiler, link with MingW libraries
#
# Experimental (does not work properly):
# WITH_NETWORK: enable networking
# WITH_DIRECTMUSIC: enable DirectMusic MIDI support


##############################################################################
#
# Configuration
#

# Makefile version tag
# it checks if the version tag in makefile.config is the same and force update outdated config files
MAKEFILE_VERSION:=2

# CONFIG_WRITER have to be found even for manual configuration
CONFIG_WRITER=makefiledir/Makefile.config_writer

ifndef MANUAL_CONFIG
# Automatic configuration
MAKE_CONFIG:=Makefile.config
MAKEFILE:=Makefile
LIB_DETECTION=makefiledir/Makefile.libdetection
CONFIG_WRITER=makefiledir/Makefile.config_writer

# Apply automatic configuration
# See target section for how this is built, suppress errors
# since first time it isn't found but make reads this twice
-include $(MAKE_CONFIG)
else
CONFIG_INCLUDED:=1
endif

# updates makefile.config if it's outdated
ifneq ($(MAKEFILE_VERSION),$(CONFIG_VERSION))
	ifndef MANUAL_CONFIG	# manual config should not check this
		UPDATECONFIG:=upgradeconf
		CONFIG_INCLUDED:=
	else
		# this should define SDL-CONFIG for manual configuration
		ifeq ($(shell uname),FreeBSD)
			SDL-CONFIG:=sdl11-config
		else
			SDL-CONFIG:=sdl-config
		endif
	endif
else
	# this should define SDL-CONFIG for manual configuration
	ifeq ($(shell uname),FreeBSD)
		SDL-CONFIG:=sdl11-config
	else
		SDL-CONFIG:=sdl-config
	endif
endif

# this is used if there aren't any makefile.config
ifndef CONFIG_INCLUDED
# sets network on by default if there aren't any config file
ENABLE_NETWORK:=1   

# paths for make install
# disabled as they would break it for some (many?) people if they were default
#PREFIX:=/usr/local
#DATA_DIR:=share/games/openttd
#BINARY_DIR:=games
#PERSONAL_DIR:=.openttd
#USE_HOMEDIR:=1

-include $(LIB_DETECTION)
endif

# Verbose filter

ifdef NOVERBOSE
VERBOSE_FILTER =  >/dev/null 2>&1
else
VERBOSE_FILTER =
endif

ifdef DISPLAY_WARNINGS
WARNING_DISPLAY:=-fstrict-aliasing
VERBOSE_FILTER =
else
WARNING_DISPLAY:=-fno-strict-aliasing
endif

ifdef SUPRESS_LANG_ERRORS
ifndef VERBOSE_FILTER
LANG_ERRORS =  >/dev/null 2>&1
endif
endif

ifdef STATIC
ifndef WIN32
ifndef OSX
ifndef MORPHOS
ifndef SKIP_STATIC_CHECK
$(error Static is only known to work on MorphOS and MacOSX!!! --- Check makefile.config for more info and howto bypass this check)
endif
endif
endif
endif
endif


# Force SDL on UNIX platforms
ifndef WITH_SDL
ifdef UNIX
$(error You need to have SDL installed in order to run OpenTTD on UNIX.)
endif
endif



##############################################################################
#
# Compiler configuration
#
CC=gcc
CXX=g++

ifdef MORPHOS
CC += -noixemul -pipe
CXX += -noixemul -pipe
endif

# Executable file extension
ifdef WIN32
EXE=.exe
else
EXE=
endif

# Set output executable names
TTD=openttd$(EXE)
ENDIAN_CHECK=endian_check$(EXE)
STRGEN=strgen/strgen$(EXE)
OSXAPP="OpenTTD.app"

# What revision are we compiling, if we have an idea?
REV_NUMBER := $(shell if test -d .svn; then svnversion . | tr -dc 0-9; fi)

ifdef RELEASE
REV:=$(RELEASE)
else
REV := $(shell if test -d .svn; then echo -n r; svnversion .; fi)
tmp_test:=$(shell echo "$(REV)" | grep "M" )
ifdef tmp_test
REV_NUMBER:=1
endif
endif

ifndef REV_NUMBER
REV_NUMBER:=0
endif

# MorphOS needs builddate
BUILDDATE=`date +%d.%m.%y`

# AMD64 needs a little more settings to work
ifeq ($(shell uname -m), x86_64)
endwarnings:=endwarnings
64_bit_warnings:=64_bit_warnings
BASECFLAGS += -m64
endif


# When calling the compiler, use these flags
# -g	debugging symbols
# -Wall	all warnings
# -s    automatic strip
#
# You may also want:
# -O	optimize or -O2 fully optimize (O's above 2 are not recommended)
# -pg	profile - generate profiling data.  See "man gprof" to use this.

CFLAGS=-Wall -Wno-multichar
CDEFS=-DWITH_REV
LDFLAGS=
LIBS=

ifdef DEBUG
# Debug mode
CDEFS += -D_DEBUG
BASECFLAGS += -g
else
ifdef PROFILE
BASECFLAGS += -pg
else
# Release mode
ifndef MORPHOS
# automatical strip breaks under morphos
BASECFLAGS += -s
LDFLAGS += -s
endif
endif

ifdef OSX
# these compilerflags makes the app run as fast as possible without making the app unstable. It works on G3 or newer
BASECFLAGS += -O3 -funroll-loops -fsched-interblock -falign-loops=16 -falign-jumps=16 -falign-functions=16 -falign-jumps-max-skip=15 -falign-loops-max-skip=15 -mdynamic-no-pic -mpowerpc-gpopt -force_cpusubtype_ALL $(WARNING_DISPLAY)
else
ifdef MORPHOS
BASECFLAGS += -O2 -funroll-loops -fexpensive-optimizations -mstring -mmultiple $(WARNING_DISPLAY)
else
BASECFLAGS += -O2 $(WARNING_DISPLAY)
endif
ifndef PROFILE
BASECFLAGS += -fomit-frame-pointer
endif
endif
endif

ifdef STATIC
ifndef OSX	# OSX can't build static if -static flag is used
LDFLAGS += -static
endif
endif

# If building on Cygwin/MingW don't link with Cygwin libs
ifdef WIN32
ifdef MINGW
ifdef CYGWIN
BASECFLAGS += -mno-cygwin
LDFLAGS += -mno-cygwin
endif
endif
endif

CFLAGS += $(BASECFLAGS)

ifdef UNIX
CDEFS += -DUNIX
endif

# SDL config
ifdef WITH_SDL
CDEFS += -DWITH_SDL
CFLAGS += `$(SDL-CONFIG) --cflags`
ifdef STATIC
LIBS += `$(SDL-CONFIG) --static-libs`
else
LIBS += `$(SDL-CONFIG) --libs`
endif
endif


# zlib config
ifdef WITH_ZLIB
	CDEFS +=  -DWITH_ZLIB
	ifdef STATIC
		ifdef OSX
# zlib is default on OSX, so everybody have it. No need for static linking
			LIBS += -lz
		else
			ifndef STATIC_ZLIB_PATH
				ifndef MANUAL_CONFIG
					# updates makefile.config with the zlib path
					UPDATECONFIG:=upgradeconf
				endif
				TEMP:=$(shell ls /lib 2>/dev/null | grep "zlib.a")$(shell ls /lib 2>/dev/null | grep "libz.a")
				ifdef TEMP
					STATIC_ZLIB_PATH:=/lib/$(TEMP)
				else
					TEMP:=$(shell ls /usr/lib 2>/dev/null | grep "zlib.a")$(shell ls /usr/lib 2>/dev/null | grep "libz.a")
					ifdef TEMP
						STATIC_ZLIB_PATH:=/usr/lib/$(TEMP)
					else
						TEMP:=$(shell ls /usr/local/lib 2>/dev/null | grep "zlib.a")$(shell ls /usr/local/lib 2>/dev/null | grep "libz.a")
						ifdef TEMP
							STATIC_ZLIB_PATH:=/usr/local/lib/$(TEMP)
						endif
					endif
				endif
			endif
			LIBS += $(STATIC_ZLIB_PATH)
		endif
	else
		LIBS += -lz
	endif
endif

# libpng config
ifdef WITH_PNG
CDEFS += -DWITH_PNG
# FreeBSD doesn't use libpng-config
ifdef FREEBSD
LIBS += -lpng
else
CFLAGS += `libpng-config --cflags`
ifdef OSX
ifdef STATIC
# Seems like we need a tiny hack for OSX static to work
LIBS += `libpng-config --prefix`/lib/libpng.a
else
LIBS += `libpng-config  --libs`
endif
else
# seems like older libpng versions are broken and need this
PNGCONFIG_FLAGS = --ldflags --libs
ifdef STATIC
LIBS += `libpng-config --static $(PNGCONFIG_FLAGS)`
else
LIBS += `libpng-config  $(PNGCONFIG_FLAGS)`
endif
endif
endif
endif

# enables/disables assert()
ifndef ENABLE_ASSERTS
CFLAGS += -DNDEBUG
endif

ifdef TRANSLATOR
STRGEN_FLAGS=-t
else
STRGEN_FLAGS=
endif


# MIDI setup
ifdef OSX
ifndef MIDI
MIDI:=$(OSXAPP)/contents/macos/track_starter
endif
endif

ifdef MIDI
CDEFS += -DEXTERNAL_PLAYER=\"$(MIDI)\"
ifdef MIDI_ARG
CDEFS += -DMIDI_ARG=\"$(MIDI_ARG)\"
endif
endif

# Experimental
ifdef WITH_NETWORK
CDEFS += -DENABLE_NETWORK
ifdef UNIX
ifndef OSX
ifndef MORPHOS
# this have caused problems on many platforms and disabling it didn't break anything
# now we test if disabling it as a general breaks it for anybody
#LIBS += -lresolv
endif
endif
endif
endif

ifdef WITH_DIRECTMUSIC
CDEFS += -DWIN32_ENABLE_DIRECTMUSIC_SUPPORT
endif

ifdef WIN32
LIBS += -lws2_32 -lwinmm -lgdi32 -ldxguid -lole32 -lstdc++
TTDLDFLAGS += -Wl,--subsystem,windows
endif

# sets up the paths for use for make install
ifdef INSTALL
# We use _PREFIXED vars here, so the paths are recalculated every time, and
# the prefix is not prepended in the makefile config
BINARY_DIR_PREFIXED:=$(PREFIX)/$(BINARY_DIR)
DATA_DIR_PREFIXED:=$(PREFIX)/$(DATA_DIR)
# We use _INSTALL vars here, these vars are the locations where the files will
# be installed
DATA_DIR_INSTALL=$(DEST_DIR)/$(DATA_DIR_PREFIXED)
BINARY_DIR_INSTALL=$(DEST_DIR)/$(BINARY_DIR_PREFIXED)
# Let the code know where to find stuff
ifdef DATA_DIR_PREFIXED
CDEFS += -DGAME_DATA_DIR=\"$(DATA_DIR_PREFIXED)/\"
endif

ifdef PERSONAL_DIR
CDEFS += -DPERSONAL_DIR=\"$(PERSONAL_DIR)/\"
endif

ifdef USE_HOMEDIR
CDEFS += -DUSE_HOMEDIR
endif
endif

##############################################################################
#
# What to compile
# (users do not want to modify anything below)
#


### Sources

ttd_SOURCES = \
	ai.c ai_build.c ai_new.c ai_pathfinder.c ai_shared.c aircraft_cmd.c \
	aircraft_gui.c airport.c airport_gui.c aystar.c bridge_gui.c \
	clear_cmd.c command.c console.c console_cmds.c disaster_cmd.c dock_gui.c dummy_land.c economy.c \
	engine.c engine_gui.c fileio.c gfx.c graph_gui.c grfspecial.c \
	industry_cmd.c industry_gui.c intro_gui.c landscape.c main_gui.c \
	minilzo.c misc.c misc_cmd.c misc_gui.c music_gui.c namegen.c network.c \
	network_gui.c news_gui.c oldloader.c order_cmd.c order_gui.c \
	pathfind.c player_gui.c players.c queue.c rail_cmd.c rail_gui.c rev.c \
	road_cmd.c road_gui.c roadveh_cmd.c roadveh_gui.c saveload.c \
	screenshot.c settings.c settings_gui.c ship_cmd.c ship_gui.c \
	smallmap_gui.c sound.c spritecache.c station_cmd.c station_gui.c \
	strings.c subsidy_gui.c terraform_gui.c texteff.c town_cmd.c \
	town_gui.c train_cmd.c train_gui.c tree_cmd.c ttd.c tunnelbridge_cmd.c \
	unmovable_cmd.c vehicle.c vehicle_gui.c viewport.c water_cmd.c widget.c window.c \

ifdef WITH_SDL
ttd_SOURCES += sdl.c
endif

ifdef WIN32
ttd_SOURCES += win32.c w32dm.c
else
ttd_SOURCES += extmidi.c unix.c
endif

ttd_OBJS = $(ttd_SOURCES:%.c=%.o)

ifdef WIN32
# Resource file
ttd_OBJS += winres.o
endif

ifdef WITH_DIRECTMUSIC
ttd_SOURCES += w32dm2.cpp
ttd_OBJS += w32dm2.o
endif

ttd_DEPS1 = $(foreach obj,$(ttd_OBJS),.deps/$(obj))
ttd_DEPS = $(ttd_DEPS1:%.o=%.P)

LANG_TXT = $(filter-out %.unfinished.txt,$(wildcard lang/*.txt))
LANGS = $(LANG_TXT:%.txt=%.lng)

C_COMPILE = $(CC) $(CFLAGS) $(CDEFS)
CXX_COMPILE = $(CXX) $(CFLAGS) $(CDEFS)

C_BUILD = $(C_COMPILE) -c
CXX_BUILD = $(CXX_COMPILE) -c

C_LINK = $(CC) $(LDFLAGS) -o



##############################################################################
#
# Targets
#


### Normal build rules


ifdef OSX
OSX:=OSX
endif


all: endian.h $(UPDATECONFIG) $(TTD) $(OSX) $(endwarnings)

endian.h: $(ENDIAN_CHECK)
	@# Check if system is LITTLE_ENDIAN or BIG_ENDIAN
	@echo 'Running endian_check'; \
		./$(ENDIAN_CHECK) > $@

$(ENDIAN_CHECK): endian_check.c
	@echo 'Compiling and Linking $@'; \
		$(CC) $(BASECFLAGS) $(CDEFS) endian_check.c -o $@


$(TTD): table/strings.h $(ttd_OBJS) $(LANGS) $(MAKE_CONFIG)
	@echo 'Compiling and Linking $@'; \
		$(C_LINK) $@ $(TTDLDFLAGS) $(ttd_OBJS) $(LIBS) $(VERBOSE_FILTER)

$(OSX):
	@mkdir -p $(OSXAPP)/Contents/MacOS
	@mkdir -p $(OSXAPP)/Contents/Resources
	@echo "APPL????" > $(OSXAPP)/Contents/PkgInfo
	@cp os/macos/ttd.icns $(OSXAPP)/Contents/Resources/openttd.icns
	@os/macos/plistgen.sh $(OSXAPP) $(REV)
	@cp os/macos/track_starter $(OSXAPP)/contents/macos
	@ls os/macos | grep -q "\.class" || \
	javac os/macos/OpenTTDMidi.java
	@cp os/macos/OpenTTDMidi.class $(OSXAPP)/contents/macos
	@cp $(TTD) $(OSXAPP)/Contents/MacOS/$(TTD)

$(endwarnings): $(64_bit_warnings)

$(64_bit_warnings):
	$(warning 64 bit CPUs will get some 64 bit specific bugs!)
	$(warning If you see any bugs, include in your bug report that you use a 64 bit CPU)

$(STRGEN): strgen/strgen.c rev.o
	@echo 'Compiling and Linking $@'; \
		$(CC) $(BASECFLAGS) $(CDEFS) -o $@ $^ $(VERBOSE_FILTER)

lang/english.lng: lang/english.txt $(STRGEN)
	@echo 'Generating $@'; \
	$(STRGEN)

table/strings.h: lang/english.lng

lang/%.lng: lang/%.txt $(STRGEN)
	@echo 'Generating $@'; \
	$(STRGEN) $(STRGEN_FLAGS) $< $(VERBOSE_FILTER) $(LANG_ERRORS)

winres.o: ttd.rc
	windres -o $@ $<


rev.c: FORCE
	@# setting the revision number in a place, there the binary can read it
	@echo 'const char _openttd_revision[] = "'$(REV)'";' >>rev.c.new
	@echo 'const int _revision_number = $(REV_NUMBER);' >>rev.c.new
	@# some additions for MorphOS versions tag
	@echo '#ifdef __MORPHOS__'  >>rev.c.new
	@echo 'const char morphos_versions_tag[] = "\\0$$VER: OpenTTD '$(REV)' ('${BUILDDATE}') � OpenTTD Team [MorphOS, PowerPC]";'  >>rev.c.new
	@echo '#endif' >>rev.c.new
	@# Only update the real rev.c if it actually changed, to prevent
	@# useless rebuilds.
	@cmp -s rev.c rev.c.new 2>/dev/null || mv rev.c.new rev.c
	@rm -f rev.c.new

FORCE:


# ttd$(EXE) is removed just to make sure people execute the right binary (openttd$(EXE))
# remove this for next release!
clean:
	@echo 'Cleaning up...'; \
	rm -rf .deps *~ $(TTD) $(STRGEN) core table/strings.h $(LANGS) $(ttd_OBJS) endian.h $(ENDIAN_CHECK) ttd$(EXE)

mrproper: clean
	rm -rf $(MAKE_CONFIG)

ifndef OSX
ifndef MORPHOS
install:
ifeq ($(INSTALL),)
	$(error make install is highly experimental at his state and not\
	tested very much - use at your own risk - to use run \"make install INSTALL:=1\" - make sure makefile.config\
	is set correctly up - run \"make upgradeconf\")
endif

ifeq ($(PREFIX), ) 
	$(error no prefix set - check makefile.config) 
endif
#	We compare against the non prefixed version here, so we won't install
#	if only the prefix has been set
ifeq ($(DATA_DIR),)
	$(error no data path set - check makefile.config)
endif
ifeq ($(BINARY_DIR),)
	$(error no binary path set - check makefile.config)
endif
# We'll install in $DEST_DIR instead of root if it is set (we don't
# care about extra /'s
	mkdir -p $(DATA_DIR_INSTALL)/lang
	mkdir -p $(DATA_DIR_INSTALL)/data
	mkdir -p $(DATA_DIR_INSTALL)/gm
	mkdir -p $(BINARY_DIR_INSTALL)
	cp $(TTD) $(BINARY_DIR_INSTALL)
	cp lang/*.lng $(DATA_DIR_INSTALL)/lang
	cp data/*.grf $(DATA_DIR_INSTALL)/data
	cp data/opntitle.dat $(DATA_DIR_INSTALL)/data
	cp media/openttd.64.png $(DATA_DIR_INSTALL)
else	#MorphOS
install:
	$(error make install is not supported on MorphOS)
endif
else	# OSX
install:
	$(error make install is not supported on MacOSX)
endif


love:
	@echo "YES! I thought you would never ask. We will have a great time. You can keep me turned on all night"

.PHONY: clean all $(OSX) install $(64_bit_warnings) $(endwarnings) love


### Automatic configuration
-include $(CONFIG_WRITER)


# Export all variables set to subprocesses (a bit dirty)
.EXPORT_ALL_VARIABLES:
upgradeconf: $(MAKE_CONFIG)
	rm $(MAKE_CONFIG)
	$(MAKE) $(MAKE_CONFIG)

.PHONY: upgradeconf


### Internal build rules

# This makes sure the .deps dir is always around.
DEPS_MAGIC := $(shell mkdir .deps > /dev/null 2>&1 || :)

# Introduce the dependencies
-include $(ttd_DEPS)

# This compiles the object file as well as silently updating its dependencies
# list at the same time. It is not an issue that they aren't around during the
# first compilation round as we just build everything at that time anyway,
# therefore we do not need to watch deps.

#@echo '$(C_BUILD) $<'; \


%.o: %.c $(MAKE_CONFIG)
	@echo 'Compiling $(*F).o'; \
		       $(C_BUILD) $< -Wp,-MD,.deps/$(*F).pp $(VERBOSE_FILTER)
	@-cp .deps/$(*F).pp .deps/$(*F).P; \
		tr ' ' '\012' < .deps/$(*F).pp \
		| sed -e 's/^\\$$//' -e '/^$$/ d' -e '/:$$/ d' -e 's/$$/ :/' \
		>> .deps/$(*F).P; \
	rm .deps/$(*F).pp

# For DirectMusic build
%.o: %.cpp  $(MAKE_CONFIG)
	$(CXX_BUILD) $<
