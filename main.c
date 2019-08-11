#include <stdio.h>

int bar( void ) {
	return 43;
}

int foo( void ) {
	return bar();
}

int main( void ) {
	printf( "Number %d", foo() );
	return 0;
}
