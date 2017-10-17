.PHONY: clean

TARGET=plasma

$(TARGET): libplasma.a
	go build .

libplasma.a: plasma.o
	ar r $@ $^

%.o: %.cc
	g++ `pkg-config --cflags --libs plasma` --std=c++11 -O2 -o $@ -c $^

clean:
	rm -f *.o *.so *.a $(TARGET)
