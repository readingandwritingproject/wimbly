#include "libpdf.h"

int main( int argc, char* argv[] ) {
  complete_certificate(
    "../static/pdf/TCRWP_Certificate.pdf",
    //"original.pdf",//
    "out_certificate.pdf",
    "In recognition of the five hours of time, care and thought invested in the challenge of implementing the Common Core State Standards, the Teachers College Reading and Writing Project presents this certificate to",
    "JOSE H. BAIRES",
    "Units of Study: Implementing Rigorous, Coherent Writing Curriculum - New York",
    "Presented on March 22, 1976"
  );
  return 0;
}
