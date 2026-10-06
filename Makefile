.PHONY : one all clean

one :
	./compile.sh $(target)

all :
	./compile.sh

clean : 
	rm compiled/*