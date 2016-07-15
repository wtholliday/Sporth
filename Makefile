default: sporth


MASTER_MAKEFILE=1

CFLAGS += -O3 -fPIC -I/usr/local/include -Wall

include config.mk
ifdef DEBUG_MODE
CFLAGS += -DDEBUG_MODE -DPOLY_DEBUG
endif

ifdef BUILD_KONA
KOBJ=$(shell find $(KONA_PATH) -name "*.o" | egrep -v "\.t\.o|main")
LIBS+=-ldl -lpthread 
CFLAGS += -I$(KONA_PATH)/src -DBUILD_KONA 
endif

ifdef BUILD_POLYSPORTH
OBJ += ugens/polysporth/s7.o 
CFLAGS += -DBUILD_POLYSPORTH
LIBS += -Wl,-export-dynamic
#UGENS += polysporth
include ugens/polysporth/Makefile
endif

ifdef BUILD_LADSPA
CFLAGS += -DBUILD_LADSPA -Iugens/ladspa/
#UGENS += ladspa/ladspa
OBJ += ugens/ladspa/load.o
endif

ifdef BUILD_JACK
CFLAGS += -DBUILD_JACK 
OBJ += util/sp_jack.o
LIBS += -ljack  -llo
endif

CLFAGS += -DRECOMPILATION

include ugens/ling/Makefile

BIN += sporth examples/parse examples/user_function util/jack_wrapper util/val \
	  util/float2bin util/jacksporth


OBJ += $(addprefix ugens/, $(addsuffix .o, $(UGENS)))

OBJ += func.o plumber.o stack.o parse.o hash.o

SPORTHLIBS = libsporth.a

LIBS += -lsoundpipe -lsndfile -lm -ldl


ifdef BUILD_DYNAMIC
#SPORTHLIBS += libsporth_dyn.so
endif

config.mk: config.def.mk
	cp config.def.mk config.mk

%.o: %.c h/ugens.h
	$(CC) $(CFLAGS) -g -c -Ih -I. $< -o $@

ugens/%.o: ugens/%.c
	$(CC) $(CFLAGS) -g -Ih -I. -c $< -o $@

util/jack_wrapper: util/jack_wrapper.c
	$(CC) $< -ljack $(LIBS) -o jack_wrapper -lm

val: util/val

util/val: util/val.c
	$(CC) $< -o $@

float2bin: util/float2bin

util/float2bin: util/float2bin.c
	$(CC) $< -o $@

jacksporth: util/jacksporth
util/jacksporth: util/jacksporth.c libsporth.a
	$(CC) $< -L. -lsporth $(LIBS) -lm -ljack -llo -o $@ 

jsporth: util/jsporth
util/jsporth: util/jsporth.c libsporth.a
	$(CC) $< $(CFLAGS) -L. -lsporth $(LIBS) -lm -ljack -o $@ 

sporth: sporth.c $(OBJ) h/ugens.h
	$(CC) sporth.c -L/usr/local/lib $(CFLAGS) -g -Ih -o $@ $(OBJ) $(KOBJ) $(LIBS) 

libsporth.a: $(OBJ) tmp.h
	$(AR) rcs libsporth.a $(KOBJ) $(OBJ) 

tmp.h: $(OBJ)
	sh util/header_gen.sh

examples/parse: examples/parse.c libsporth.a h/ugens.h
	gcc $< $(CFLAGS) -g -Ih -o $@ libsporth.a $(LIBS)

examples/user_function: examples/user_function.c libsporth.a h/ugens.h
	gcc $< $(CFLAGS) -g -Ih -o $@ libsporth.a $(LIBS)

include util/luasporth/Makefile

install: $(SPORTHLIBS) sporth tmp.h
	install sporth /usr/local/bin
	install tmp.h /usr/local/include/sporth.h
	install $(SPORTHLIBS) /usr/local/lib
	mkdir -p /usr/local/share/sporth
	install ugen_reference.txt /usr/local/share/sporth
	install util/ugen_lookup /usr/local/bin
	install util/spparse /usr/local/bin

clean:
	rm -rf $(OBJ)
	rm -rf $(BIN)
	rm -rf tmp.h
	rm -rf libsporth.a libsporth_dyn.so

