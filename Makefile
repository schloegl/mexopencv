#
# This Makefile compiles mexopencv for a variaty of platforms including
#  - Matlab on host platform
#         usage: MATLABDIR=/usr/local/MATLAB/R2013a make -B
#  - Octave on host platform
#         usage: make -B
#  - 64bit-Matlab on Windows using MXE
#         usage: MEXEXT=mexw32 make -B
#  - 32bit-Matlab on Windows using MXE
#         usage: MEXEXT=mexw64 make -B
#
# How to install MXE (i.e. cross-compile for target:MSWindows)
#  1) download and installed from http://mxe.cc,
#  2) build "make opencv",
#  3) set path to mxe by defining CROSS/CROSS64
#  4) Copy the directory MATLAB/Ryyyy/bin/<platform>/ from the Matlab/Windows version
#     and point GNUMEX/GNUMEX64 to the directory
#  5) Copy the directory MATLAB/Ryyyy/extern/include from the Matlab/Windows version
#     and set W32MAT_INC/W64MAT_INC to the directory
#
# The target platform can be selected by setting MEXEXT to the appropriate extension.
#
# Copyright (C) 2014 Alois Schloegl
#


## Set path to mxe build
CROSS        = $(HOME)/src/mxe/usr/bin/i686-pc-mingw32.static
CROSS64      = $(HOME)/src/mxe/usr/bin/x86_64-w64-mingw32.static

# include directory for Win32-Matlab include
W32MAT_INC = $(HOME)/bin/win32/Matlab/R2010b/extern/include/ $(shell $(CROSS)-pkg-config --cflags-only-I opencv)
W64MAT_INC = $(HOME)/bin/win64/Matlab/R2010b/extern/include/ $(shell $(CROSS64)-pkg-config --cflags-only-I opencv)
# path to GNUMEX libraries, available from here http://sourceforge.net/projects/gnumex/
GNUMEX   = $(HOME)/bin/win32/gnumex
GNUMEX64 = $(HOME)/bin/win64/gnumex

MATLABDIR   ?= /usr/local/matlab

### select target - uncomment proper line
#MEXEXT      ?= mexw32
#MEXEXT      ?= mexw64
#MEXEXT      ?= mex
MEXEXT      ?= $(shell $(MATLABDIR)/bin/mexext)

MV          ?= mv
RM          ?= rm
DOXYGEN     ?= doxygen
TARGETDIR   := +cv
INCLUDEDIR  := include
LIBDIR      := lib
SRCDIR	    := src
MEXDIR	    := $(SRCDIR)/$(TARGETDIR)
SRCS        := $(wildcard $(MEXDIR)/*.cpp) $(wildcard $(MEXDIR)/private/*.cpp)

ifeq (,$(MEXEXT))
# default Octave
MEXEXT       = mex
endif

ifeq (mexw32,$(MEXEXT))  ### WIN32/MATLAB
AR          := $(CROSS)-ar
MEX         ?= $(CROSS)-g++ -shared $(GNUMEX)/mex.def -DMATLAB_MEX_FILE $(DEFINES) -I$(W32MAT_INC) -O2
#MATLAB      ?= $(MATLABDIR)/bin/matlab -nodisplay -r

MKOUTARG    := -o
C_FLAGS     := -I$(INCLUDEDIR) $(shell $(CROSS)-pkg-config --cflags opencv)
LD_FLAGS    := -L$(LIBDIR) -lMxArray -L$(HOME)/src/mxe/usr/i686-pc-mingw32.static/lib $(shell $(CROSS)-pkg-config --libs opencv)  -L$(GNUMEX) -llibmx -llibmex

else
ifeq (mexw64,$(MEXEXT))  ### WIN64/MATLAB
AR          := $(CROSS64)-ar
MEX         ?= $(CROSS64)-g++ -shared $(GNUMEX64)/mex.def -DMATLAB_MEX_FILE $(DEFINES) -I$(W64MAT_INC) -O2 -DlargeArrayDims
#MATLAB      ?= $(MATLABDIR)/bin/matlab -nodisplay -r

MKOUTARG    := -o
C_FLAGS     := -I$(INCLUDEDIR) $(shell $(CROSS64)-pkg-config --cflags opencv)
LD_FLAGS    := -L$(LIBDIR) -lMxArray -L$(HOME)/src/mxe/usr/x86_64-w64-mingw32.static/lib/ $(shell $(CROSS64)-pkg-config --libs opencv)  -L$(GNUMEX64) -llibmx -llibmex

else
ifeq (mex,$(MEXEXT))  ### OCTAVE
AR          := ar
MEX         ?= mkoctfile --mex
MATLAB      ?= octave --norc --eval
MEXEXT      := mex
MKOUTARG    := -o
C_FLAGS     := -I$(INCLUDEDIR) $(shell pkg-config --cflags opencv)
LD_FLAGS    := -Wl,-lMxArray -Wl,-L$(LIBDIR) -Wl,$(shell pkg-config --libs opencv)

else
ifneq (,$(MEXEXT))  ### MATLAB (native)
AR          := ar
MEX         ?= $(MATLABDIR)/bin/mex
MATLAB      ?= $(MATLABDIR)/bin/matlab -nodisplay -r
MKOUTARG    := -output
C_FLAGS     := -cxx -largeArrayDims -I$(INCLUDEDIR) $(shell pkg-config --cflags opencv)
LD_FLAGS    := -L$(LIBDIR) -lMxArray $(shell pkg-config --libs opencv)
MATLABMEX   := 1

endif
endif
endif
endif

TARGETS     := $(subst $(MEXDIR), $(TARGETDIR), $(SRCS:.cpp=.$(MEXEXT)))

VPATH       = $(TARGETDIR):$(SRCDIR):$(MEXDIR):$(TARGETDIR)/private:$(SRCDIR)/private

.PHONY : all clean doc test

all: $(TARGETS)

$(LIBDIR)/libMxArray.a: $(SRCDIR)/MxArray.cpp $(INCLUDEDIR)/MxArray.hpp
ifdef MATLABMEX
	## Matlab ##
	$(MEX) -c $(C_FLAGS) "$<" -outdir $(LIBDIR)
else
	## Octave ##
	$(MEX) -c $(C_FLAGS) "$<" -o $(LIBDIR)/MxArray.o
endif
	rm -f $(LIBDIR)/libMxArray.a
	$(AR) -cq $(LIBDIR)/libMxArray.a $(LIBDIR)/MxArray.o
	$(RM) -f $(LIBDIR)/*.o

%.$(MEXEXT): %.cpp $(LIBDIR)/libMxArray.a $(INCLUDEDIR)/mexopencv.hpp
	$(MEX) $(C_FLAGS) "$<" $(LD_FLAGS) $(MKOUTARG) "$@"

clean:
	$(RM) -rf $(LIBDIR)/*.a $(TARGETDIR)/*.$(MEXEXT) $(TARGETDIR)/private/*.$(MEXEXT)

doc:
	$(DOXYGEN) Doxyfile

test:
	$(MATLAB) "addpath(pwd);cd test;try,UnitTest;catch e,disp(e);end;exit;"
