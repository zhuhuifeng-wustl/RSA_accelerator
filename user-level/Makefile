CFLAGS = -g -Wall $(INCLUDES)

default: wrapper-test

interface-test: c-interface.o c-wrapper.o instructions.o
wrapper-test: c-wrapper.o instructions.o

c-interface.o: c-interface.h c-wrapper.h instructions.h
c-wrapper.o: c-wrapper.h exteuc.h 
instructions.o: instructions.h
prime-generator.o: prime-generator.h

.PHONY: clean
clean:
	rm -f *.o *~ 
	rm -f interface-test
	rm -f wrapper-test
	rm -f prime-generator
	rm -f exteuc
