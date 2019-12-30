
#include <iostream>

#include <cstdio>
#include <ctime>

#include <podofo/podofo.h>
using namespace PoDoFo;


#define DANCING_GIRL_PDF_PATH "/var/www/libpdf/dancing_girl.jpg"


// for appending the contents of iname2 to the end of iname1
extern "C" void combine_files( const char *iname1, const char *iname2, const char *oname );

// for stamping any file with user and copyright information
extern "C" void mark_file( const char *iname, const char *oname, const char *name, const char *email );
extern "C" void mark_buffer( const char *buffer, long buffer_size, const char *oname, const char *name, const char *email );

// for generating certificates from static/pdf/TCRWP_Certificate.pdf
extern "C" void complete_certificate( const char *iname, const char *oname, const char *descriptive_text, const char *name, const char *title, const char *date );


void combine_files( const char *iname1, const char *iname2, const char *oname ) {

  PdfMemDocument document1( iname1 );
  PdfMemDocument document2( iname2 );

  document1.Append( document2 );

  document1.SetPdfVersion( ePdfVersion_1_0 );
  document1.Write( oname );

  //document1.Close();
  //document2.Close();

}


void mark_file( const char* iname, const char *oname, const char* name, const char* email ) {

  time_t rawtime;
  struct tm * timeinfo;

  time (&rawtime);
  timeinfo = localtime (&rawtime);

  PdfMemDocument document( iname );
  PdfPainter painter;
  PdfRect rect;
  PdfPage* pPage;
  PdfFont* pFont;

  // add image
  PdfImage image( &document );
  image.LoadFromFile( DANCING_GIRL_PDF_PATH );

  int nPages = document.GetPageCount();

  try {

    for ( int i = 0; i < nPages; ++i ) {

      pPage = document.GetPage( i );

      if( !pPage ) {
        PODOFO_RAISE_ERROR( ePdfError_InvalidHandle );
      }

      painter.SetPage( pPage );
      pFont = document.CreateFont( "Courier" );

      if( !pFont ) {
        PODOFO_RAISE_ERROR( ePdfError_InvalidHandle );
      }

      pFont->SetFontSize( 8.0 );

      painter.SetFont( pFont );
      painter.SetTransformationMatrix( 0, 1, -1, 0, 0, 0 );

      rect = PdfRect( 8, -35, 400, 25 );

      // white internal fill
      painter.SetColor( 1, 1, 1 );
      //DEPRECATED:
      //painter.FillRect( rect );
      //NEW:
      painter.Rectangle( rect );
      painter.Fill();

      painter.SetStrokeWidth( 0.1 );

      // black outline
      painter.SetColor( 0, 0, 0 );
      //DEPRECATED:
      //painter.DrawRect( rect );
      //NEW:
      painter.Rectangle( rect );
      painter.Stroke();
      
      
      // insert image
      painter.DrawImage( 388, -33, &image, 0.09, 0.09 );

      char line1[128];
      char line2[128];

      snprintf( line1, 128, "Prepared for: %s (%s)", name, email );
      snprintf( line2, 128, "Copyright %d Reading and Writing Project. Page %d of %d", 1900 + (*timeinfo).tm_year, i+1, nPages );

      painter.DrawText( 32, -20, line1 );
      painter.DrawText( 32, -30, line2 );

      painter.SetStrokeWidth( 1.0 );

      //DEPRECATD:
      //painter.DrawCircle( 20, -22, 7 );
      //NEW:
      painter.Circle( 20, -22, 7 );
      painter.Stroke();
      

      pFont->SetFontSize( 16.0 );
      painter.SetFont( pFont );

      painter.DrawText( 15.1, -25.3, "c" );

      painter.FinishPage();

    }

	document.GetInfo()->SetCreator ( PdfString( "stamp" ) );
	document.GetInfo()->SetAuthor  ( PdfString( "Reading and Writing Project" ) );
	document.GetInfo()->SetTitle   ( PdfString( "Curriculum" ) );
	document.GetInfo()->SetSubject ( PdfString( "Copyrighted Materials" ) );
	document.GetInfo()->SetKeywords( PdfString( "Reading;Writing" ) );
    document.GetInfo()->SetProducer( PdfString( "stamp" ) );

    document.SetPdfVersion( ePdfVersion_1_0 );
	document.Write( oname );

    //document.Close();

  }
  catch ( const PdfError & e ) {
    try {
	  painter.FinishPage();
	} catch( ... ) {
	}
	throw e;
  }

}


void mark_buffer( const char* buffer, long buffer_size, const char *oname, const char* name, const char* email ) {

  time_t rawtime;
  struct tm * timeinfo;

  time (&rawtime);
  timeinfo = localtime (&rawtime);

  PdfMemDocument document;
  document.Load( buffer, buffer_size );
  PdfPainter painter;
  PdfRect rect;
  PdfPage* pPage;
  PdfFont* pFont;

  // add image
  PdfImage image( &document );
  image.LoadFromFile( DANCING_GIRL_PDF_PATH );

  int nPages = document.GetPageCount();

  try {

    for ( int i = 0; i < nPages; ++i ) {

      pPage = document.GetPage( i );

      if( !pPage ) {
        PODOFO_RAISE_ERROR( ePdfError_InvalidHandle );
      }

      painter.SetPage( pPage );
      pFont = document.CreateFont( "Courier" );

      if( !pFont ) {
        PODOFO_RAISE_ERROR( ePdfError_InvalidHandle );
      }

      pFont->SetFontSize( 8.0 );

      painter.SetFont( pFont );
      painter.SetTransformationMatrix( 0, 1, -1, 0, 0, 0 );

      rect = PdfRect( 8, -35, 400, 25 );

      // white internal fill
      painter.SetColor( 1, 1, 1 );
      //DEPRECATED:
      //painter.FillRect( rect );
      //NEW:
      painter.Rectangle( rect );
      painter.Fill();

      painter.SetStrokeWidth( 0.1 );

      // black outline
      painter.SetColor( 0, 0, 0 );
      //DEPRECATED:
      //painter.DrawRect( rect );
      //NEW:
      painter.Rectangle( rect );
      painter.Stroke();
      
      

      // insert image
      painter.DrawImage( 388, -33, &image, 0.09, 0.09 );

      char line1[128];
      char line2[128];

      snprintf( line1, 128, "Prepared for: %s (%s)", name, email );
      snprintf( line2, 128, "Copyright %d Reading and Writing Project. Page %d of %d", 1900 + (*timeinfo).tm_year, i+1, nPages );

      painter.DrawText( 32, -20, line1 );
      painter.DrawText( 32, -30, line2 );

      painter.SetStrokeWidth( 1.0 );

      //DEPRECATD:
      //painter.DrawCircle( 20, -22, 7 );
      //NEW:
      painter.Circle( 20, -22, 7 );
      painter.Stroke();
      

      pFont->SetFontSize( 16.0 );
      painter.SetFont( pFont );

      painter.DrawText( 15.1, -25.3, "c" );

      painter.FinishPage();

    }

	document.GetInfo()->SetCreator ( PdfString( "stamp" ) );
	document.GetInfo()->SetAuthor  ( PdfString( "Reading and Writing Project" ) );
	document.GetInfo()->SetTitle   ( PdfString( "Curriculum" ) );
	document.GetInfo()->SetSubject ( PdfString( "Copyrighted Materials" ) );
	document.GetInfo()->SetKeywords( PdfString( "Reading;Writing" ) );
    document.GetInfo()->SetProducer( PdfString( "stamp" ) );

    document.SetPdfVersion( ePdfVersion_1_0 );
	document.Write( oname );

    //document.Close();

  }
  catch ( const PdfError & e ) {
    try {
	  painter.FinishPage();
	} catch( ... ) {
	}
	throw e;
  }

}


void complete_certificate( const char *iname, const char *oname, const char *descriptive_text, const char *name, const char *title, const char *date ) {

  PdfMemDocument document( iname );
  PdfPainter painter;
  PdfRect descriptive_rect;
  PdfRect name_rect;
  PdfRect title_rect;
  PdfRect date_rect;
  PdfPage* pPage;
  PdfFont* pFont1;
  PdfFont* pFont2;

  try {

    pPage = document.GetPage( 0 );

    if( !pPage ) {
      PODOFO_RAISE_ERROR( ePdfError_InvalidHandle );
    }

    painter.SetPage( pPage );
    //pFont = document.CreateFont( "Helvetica Bold Oblique" );


    descriptive_rect = PdfRect( 100, 330, 590, 70 );
    name_rect = PdfRect( 100, 310, 590, 25 );
    title_rect = PdfRect( 100, 206, 590, 25 );
    date_rect = PdfRect( 100, 267, 590, 25 );

    // (black outlines to see the rectangles)
    //painter.SetColor( 0, 0, 0 );
    //painter.DrawRect( descriptive_rect );
    //painter.DrawRect( name_rect );
    //painter.DrawRect( title_rect );
    //painter.DrawRect( date_rect );

    /*
    Acrobat reader supports 14 PDF core fonts. Developers don't need to embed
    these fonts in any PDF file while working with Aspose.Pdf. These 14 fonts are:

    Courier
    Courier-Bold
    Courier-BoldOblique
    Courier-Oblique
    Helvetica
    Helvetica-Bold
    Helvetica-BoldOblique
    Helvetica-Oblique
    Symbol
    Times-Bold
    Times-BoldItalic
    Times-Italic
    Times-Roman
    ZapfDingbats
    */

    pFont1 = document.CreateFont( "Times-Roman" );
    pFont2 = document.CreateFont( "Times-Italic" );
    //if( !pFont ) {
    //  PODOFO_RAISE_ERROR( ePdfError_InvalidHandle );
    //}

    pFont1->SetFontSize( 14.5 );
    painter.SetFont( pFont1 );
    painter.DrawMultiLineText( descriptive_rect, descriptive_text, ePdfAlignment_Center, ePdfVerticalAlignment_Center );

    pFont1->SetFontSize( 16.0 );
    painter.SetColor( 0.31, 0.06, 0.06 );
    painter.DrawMultiLineText( name_rect, name, ePdfAlignment_Center, ePdfVerticalAlignment_Center );

    pFont2->SetFontSize( 12.0 );
    painter.SetFont( pFont2 );
    painter.SetColor( 0.06, 0.06, 0.31 );
    painter.DrawMultiLineText( date_rect, date, ePdfAlignment_Center, ePdfVerticalAlignment_Center );

    pFont1->SetFontSize( 15.0 );
    painter.SetFont( pFont1 );
    painter.DrawMultiLineText( title_rect, title, ePdfAlignment_Center, ePdfVerticalAlignment_Center );


    //char descriptive_text_buffer[1024];
    //char name_buffer[128];
    //char title_buffer[256];
    //char date_buffer[128];

    //snprintf( descriptive_text_buffer, 1024, "%s (%s)", descript );
    //snprintf( line2, 128, "[[ %s ]]", descriptive_text );

    //painter.DrawText( 32, 30, line1 );
    //painter.DrawText( 32, 150, line2 );

    //painter.SetStrokeWidth( 1.0 );

    //painter.DrawCircle( 20, -22, 7 );

    //pFont->SetFontSize( 16.0 );
    //painter.SetFont( pFont );

    //painter.DrawText( 15.1, -25.3, "c" );

    painter.FinishPage();

	document.GetInfo()->SetCreator ( PdfString( "stamp" ) );
	document.GetInfo()->SetAuthor  ( PdfString( "Reading and Writing Project" ) );
	document.GetInfo()->SetTitle   ( PdfString( "Certificate" ) );
	document.GetInfo()->SetSubject ( PdfString( "Personalized" ) );
	document.GetInfo()->SetKeywords( PdfString( "Reading;Writing" ) );
    document.GetInfo()->SetProducer( PdfString( "stamp" ) );

    document.SetPdfVersion( ePdfVersion_1_0 );
	document.Write( oname );

    //document.Close();

  }
  catch ( const PdfError & e ) {
    try {
	  painter.FinishPage();
	} catch( ... ) {
	}
	throw e;
  }
}
