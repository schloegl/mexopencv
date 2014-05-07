MATLABDIR   ?= /usr/local/matlab
MEX         ?= mkoctfile --mex #$(MATLABDIR)/bin/mex
MV          ?= mv
AR          ?= ar
RM          ?= rm
DOXYGEN     ?= doxygen
MEXEXT      ?= mex #$(shell $(MATLABDIR)/bin/mexext)
MATLAB      ?= $(MATLABDIR)/bin/matlab
TARGETDIR   := +cv
INCLUDEDIR  := include
LIBDIR      := lib
SRCDIR	    := src
MEXDIR	    := $(SRCDIR)/$(TARGETDIR)
SRCS        := $(wildcard $(MEXDIR)/*.cpp) $(wildcard $(MEXDIR)/private/*.cpp)
TARGETS     := $(subst $(MEXDIR), $(TARGETDIR), $(SRCS:.cpp=.$(MEXEXT)))
C_FLAGS     := -cxx -largeArrayDims -I$(INCLUDEDIR) $(shell pkg-config --cflags opencv)
C_FLAGS     := -I$(INCLUDEDIR) $(shell pkg-config --cflags opencv)
LD_FLAGS    := -Wl,-L$(LIBDIR) -Wl,$(shell pkg-config --libs opencv)

VPATH       = $(TARGETDIR):$(SRCDIR):$(MEXDIR):$(TARGETDIR)/private:$(SRCDIR)/private

.PHONY : all clean doc test

all: $(TARGETS)

$(LIBDIR)/libMxArray.a: $(SRCDIR)/MxArray.cpp $(INCLUDEDIR)/MxArray.hpp
	$(MEX) -c $(C_FLAGS) $< -o $(LIBDIR)/MxArray.o
	$(AR) -cq $(LIBDIR)/libMxArray.a $(LIBDIR)/MxArray.o
	$(RM) -f $(LIBDIR)/*.o

%.$(MEXEXT): %.cpp $(LIBDIR)/libMxArray.a $(INCLUDEDIR)/mexopencv.hpp
	$(MEX) $(C_FLAGS) $< -Wl,-lMxArray $(LD_FLAGS) -o $@

clean:
	$(RM) -rf $(LIBDIR)/*.a $(TARGETDIR)/*.$(MEXEXT) $(TARGETDIR)/private/*.$(MEXEXT)

doc:
	$(DOXYGEN) Doxyfile

test:
	$(MATLAB) -nodisplay -r "addpath(pwd);cd test;try,UnitTest;catch e,disp(e.getReport);end;exit;"
