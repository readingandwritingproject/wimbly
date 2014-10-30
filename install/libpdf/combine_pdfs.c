#include "libpdf.h"

int main( int argc, char* argv[] ) {
  combine_files( argv[1], argv[2], "out.pdf" );
  return 0;
}
