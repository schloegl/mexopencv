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
# Copyright (C) 2014, 2015 Alois Schloegl
#


## Set path to mxe build
CROSS        = $(HOME)/src/mxe/usr/bin/i686-w64-mingw32.static
CROSS64      = $(HOME)/src/mxe/usr/bin/x86_64-w64-mingw32.static


# Include directory containing mex.h
# Interestingly, this can also point to /usr/include/octave-3.8.2/octave/mex.h
# and compiling will still work. However ABI compatibility is not tested yet.
W32MAT_INC = $(HOME)/bin/win32/Matlab/R2010b/extern/include/
W64MAT_INC = $(HOME)/bin/win64/Matlab/R2010b/extern/include/

# path to GNUMEX libraries, available from here http://sourceforge.net/projects/gnumex/
GNUMEX   = $(HOME)/bin/win32/gnumex
GNUMEX64 = $(HOME)/bin/win64/gnumex

MATLABDIR   ?= /usr/local/matlab

### select target - uncomment proper line
#MEXEXT      ?= mexw32
#MEXEXT      ?= mexw64
MEXEXT      ?= $(shell $(MATLABDIR)/bin/mexext)
MEXEXT      ?= mex

MV          ?= mv
RM          ?= rm
DOXYGEN     ?= doxygen
TARGETDIR   := +cv
INCLUDEDIR  := include
LIBDIR      := lib
SRCDIR	    := src
MEXDIR	    := $(SRCDIR)/$(TARGETDIR)
SRCS        := $(wildcard $(MEXDIR)/*.cpp) $(wildcard $(MEXDIR)/private/*.cpp)


ifeq (mexw32,$(MEXEXT))  ### WIN32/MATLAB
AR          := $(CROSS)-ar
MEX         ?= $(CROSS)-g++ -shared -DMATLAB_MEX_FILE -I$(W32MAT_INC) -O2
#MATLAB      ?= $(MATLABDIR)/bin/matlab -nodisplay -r

MKOUTARG    := -o
C_FLAGS     := -I$(INCLUDEDIR) $(shell $(CROSS)-pkg-config --cflags-only-I opencv)
LD_FLAGS    := $(shell $(CROSS)-pkg-config --libs-only-l opencv) -L$(GNUMEX) -llibmx -llibmex

else
ifeq (mexw64,$(MEXEXT))  ### WIN64/MATLAB
AR          := $(CROSS64)-ar
MEX         ?= $(CROSS64)-g++ -shared -DMATLAB_MEX_FILE -I$(W64MAT_INC) -O2 -DlargeArrayDims
#MATLAB      ?= $(MATLABDIR)/bin/matlab -nodisplay -r

MKOUTARG    := -o
C_FLAGS     := -I$(INCLUDEDIR) $(shell $(CROSS64)-pkg-config --cflags-only-I opencv)
LD_FLAGS    := $(shell $(CROSS64)-pkg-config --libs-only-l opencv) -L$(GNUMEX64) -llibmx -llibmex

else
ifeq (mex,$(MEXEXT))  ### OCTAVE
AR          := ar
MEX         ?= mkoctfile --mex
MATLAB      ?= octave --norc --eval
MKOUTARG    := -o
C_FLAGS     := -I$(INCLUDEDIR) $(shell pkg-config --cflags opencv)
LD_FLAGS    := -Wl,$(shell pkg-config --libs-only-l opencv)

else
ifneq (,$(MEXEXT))  ### MATLAB (native)
AR          := ar
MEX         ?= $(MATLABDIR)/bin/mex
MATLAB      ?= $(MATLABDIR)/bin/matlab -nodisplay -r
MKOUTARG    := -output
C_FLAGS     := -cxx -largeArrayDims -I$(INCLUDEDIR) $(shell pkg-config --cflags opencv)
LD_FLAGS    := $(shell pkg-config --libs-only-l opencv)
MATLABMEX   := 1

endif
endif
endif
endif

TARGETS     := $(subst $(MEXDIR), $(TARGETDIR), $(SRCS:.cpp=.$(MEXEXT)))

VPATH       = $(TARGETDIR):$(SRCDIR):$(MEXDIR):$(TARGETDIR)/private:$(SRCDIR)/private

.PHONY : all clean doc test

all: $(TARGETS)

$(LIBDIR)/MxArray.o: $(SRCDIR)/MxArray.cpp $(INCLUDEDIR)/MxArray.hpp
ifdef MATLABMEX
	## Matlab ##
	$(MEX) -c $(C_FLAGS) "$<" -outdir $(LIBDIR)
else
	## Octave ##
	$(MEX) -c $(C_FLAGS) "$<" -o $(LIBDIR)/MxArray.o
endif

$(LIBDIR)/libMxArray.a: $(LIBDIR)/MxArray.o
	rm -f "$@"
	$(AR) -cq "$@" "$<"

%.$(MEXEXT): %.cpp $(LIBDIR)/MxArray.o $(INCLUDEDIR)/mexopencv.hpp
	$(MEX) $(C_FLAGS) "$<" $(LIBDIR)/MxArray.o $(LD_FLAGS) $(MKOUTARG) "$@"

clean:
	$(RM) -rf *.o $(LIBDIR)/*.a $(TARGETDIR)/*.$(MEXEXT) $(TARGETDIR)/private/*.$(MEXEXT)

doc:
	$(DOXYGEN) Doxyfile

test:
	$(MATLAB) "addpath(pwd);cd test;try,UnitTest;catch e,disp(e);end;exit;"
