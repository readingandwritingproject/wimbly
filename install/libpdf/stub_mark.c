#include "libpdf.h"

int main( int argc, char* argv[] ) {
  mark_file( argv[1], "out.pdf", "Daniel Rubin", "daniel@readingandwritingproject.com" );
  return 0;
}
