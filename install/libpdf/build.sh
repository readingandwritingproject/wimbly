
rm -v libpdf.o
echo 'building library object'
g++ -c libpdf.cpp -fPIC

rm -v libpdf.so
echo 'making shared library'
gcc -shared -o libpdf.so libpdf.o -lpodofo

#rm -v libstamp.a
#echo 'making library archive'
#ar crf libstamp.a libstamp.o

rm -v stub_mark
echo 'compiling stub_mark'
gcc stub_mark.c -o stub_mark -L. -lpdf

rm -v stub_certificate
echo 'compiling stub_certificate'
gcc stub_certificate.c -o stub_certificate -L. -lpdf

rm -v combine_pdfs
echo 'compiling combine_pdfs'
gcc combine_pdfs.c -o combine_pdfs -L. -lpdf

echo '---'
echo '$ LD_LIBRARY_PATH=./ ./stub_mark original.pdf'
echo '$ LD_LIBRARY_PATH=./ ./stub_certificate'
echo '$ LD_LIBRARY_PATH=./ ./combine_pdfs one.pdf two.pdf'
echo '---'
