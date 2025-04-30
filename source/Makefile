objs = fpx86.o tester.o
flags =
assb = as
name = fpx86

all: $(name)

$(name): $(objs)
	ld	-o $(name) $(objs)
%.o: %.asm
	$(assb)	$< -o $@
clean:
	rm	-f $(objs) $(name) && clear

