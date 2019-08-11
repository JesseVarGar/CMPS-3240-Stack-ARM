CC=gcc
FLAGS=-O0 -Wall

main.s: main.c
	$(CC) $(FLAGS) -S $< -o $@

