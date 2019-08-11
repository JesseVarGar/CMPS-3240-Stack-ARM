CC=gcc
FLAGS=-Wall

all: main.s manyargs.s

main.s: main.c
	$(CC) $(FLAGS) -S $< -o $@

manyargs.s: manyargs.c
	$(CC) $(FLAGS) -S $< -o $@

