
// for appending the contents of iname2 to the end of iname1
void combine_files( const char *iname1, const char *iname2, const char *oname );

// for stamping any file with user and copyright information
void mark_file( const char *iname, const char *oname, const char *name, const char *email );
void mark_buffer( const char *buffer, const char *oname, const char *name, const char *email );

// for generating certificates from static/pdf/TCRWP_Certificate.pdf
void complete_certificate( const char *iname, const char *oname, const char *descriptive_text, const char *name, const char *title, const char *date );
