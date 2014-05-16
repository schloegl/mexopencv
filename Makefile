MATLABDIR   ?= /usr/local/matlab
### for building with octave, make sure MATLABDIR does not point to a valid directory
MEXEXT      ?= $(shell $(MATLABDIR)/bin/mexext)
MV          ?= mv
AR          ?= ar
RM          ?= rm
DOXYGEN     ?= doxygen
TARGETDIR   := +cv
INCLUDEDIR  := include
LIBDIR      := lib
SRCDIR	    := src
MEXDIR	    := $(SRCDIR)/$(TARGETDIR)
SRCS        := $(wildcard $(MEXDIR)/*.cpp) $(wildcard $(MEXDIR)/private/*.cpp)

ifeq (,$(MEXEXT))
  MEX         ?= mkoctfile --mex
  MATLAB      ?= octave --norc --eval
  MEXEXT      := mex
  MKOUTARG    := -o
  C_FLAGS     := -I$(INCLUDEDIR) $(shell pkg-config --cflags opencv)
  LD_FLAGS    := -Wl,-lMxArray -Wl,-L$(LIBDIR) -Wl,$(shell pkg-config --libs opencv)
else
  MEX         ?= $(MATLABDIR)/bin/mex
  MATLAB      ?= $(MATLABDIR)/bin/matlab  -nodisplay -r
  MKOUTARG    := -output
  C_FLAGS     := -cxx -largeArrayDims -I$(INCLUDEDIR) $(shell pkg-config --cflags opencv)
  LD_FLAGS    := -lMxArray -L$(LIBDIR) $(shell pkg-config --libs opencv)
endif
TARGETS     := $(subst $(MEXDIR), $(TARGETDIR), $(SRCS:.cpp=.$(MEXEXT)))

VPATH       = $(TARGETDIR):$(SRCDIR):$(MEXDIR):$(TARGETDIR)/private:$(SRCDIR)/private

.PHONY : all clean doc test

all: $(TARGETS)

$(LIBDIR)/libMxArray.a: $(SRCDIR)/MxArray.cpp $(INCLUDEDIR)/MxArray.hpp
ifneq (mex,$(MEXEXT))
	## Matlab ##
	$(MEX) -c $(C_FLAGS) "$<" -outdir $(LIBDIR)
else
	## Octave ##
	$(MEX) -c $(C_FLAGS) "$<" -o $(LIBDIR)/MxArray.o
endif
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
