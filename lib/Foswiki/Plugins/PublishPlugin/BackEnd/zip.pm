#
# Copyright (C) 2005 Crawford Currie, http://c-dot.co.uk
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html
#
# Archive::Zip writer module for PublishPlugin
#
package Foswiki::Plugins::PublishPlugin::BackEnd::zip;

use strict;

use Foswiki::Plugins::PublishPlugin::BackEnd;
our @ISA = ('Foswiki::Plugins::PublishPlugin::BackEnd');

use constant DESCRIPTION =>
  'HTML compressed into a single zip file for shipping.';

use Foswiki::Func;
use File::Path;
use Error qw( :try );
use Text::Unidecode;
use Encode;

sub new {
    my $class = shift;
    my ($params) = @_;
    $params->{outfile} ||= "zip";
    my $this = $class->SUPER::new(@_);

    eval 'use Archive::Zip qw( :ERROR_CODES :CONSTANTS )';
    die $@ if $@;
    $this->{zip} = Archive::Zip->new();

    $this->{zipped} = {}; # remember zipped names to resolve collisions

    return $this;
}

sub param_schema {
    my $class = shift;
    return {
        outfile => {
            default => 'zip',
            validator =>
              \&Foswiki::Plugins::PublishPlugin::Publisher::validateFilename
        },
        outwebtopic => {
            default => ''
        },
        outattachment => {
            default => ''
        },
        catpdf => {
            default => ''
        },
        %{ $class->SUPER::param_schema() }
    };
}

sub decodeUri {
    my ( $this, $file ) = @_;

    $file = decode($Foswiki::cfg{Site}{CharSet}, $file);
    $file = unidecode($file);

    $file =~ s#^/##;

    return $file;
}

# resolve collisions due to umlauts etc.
# also windows might get stung by up/lower cased letters
sub addToZip {
    my ( $this, $file ) = @_;

    my $original = $file;
    my $collision = 0;
    while($this->{zipped}->{$file} || $this->{zipped}->{lc($file)}) {
        $collision++;
        $file = $original;
        $file =~ s#(\.[^.]*)?$#_$collision$1#;
    }
    $this->{zipped}->{$file} = 1;
    $this->{zipped}->{lc($file)} = 1;

    return $file;
}

sub addDirectory {
    my ( $this, $dir ) = @_;

    $dir = $this->decodeUri($dir);

    $this->{logger}->logError("Error adding $dir")
      unless $this->{zip}->addDirectory($dir);

    return $dir;
}

sub addString {
    my ( $this, $string, $file ) = @_;
    $file = $this->decodeUri($file);
    $file = $this->addToZip($file);

    $this->{logger}->logError("Error adding $string")
      unless $this->{zip}->addString( $string, $file );

    return $file;
}

sub addFile {
    my ( $this, $from, $to ) = @_;
    $to = $this->decodeUri($to);
    $to = $this->addToZip($to);

    $this->{logger}->logError("Error adding $from")
      unless $this->{zip}->addFile( $from, $to );

    return $to;
}

sub addIndex {
    my ( $this, $string ) = @_;
    $this->addString( $string, 'index.html' );
}

sub close {
    my $this = shift;
    my $dir  = $this->{path};
    eval { File::Path::mkpath($dir) };
    $this->{logger}->logError($@) if $@;
    my $landed = "$this->{params}->{outfile}.zip";
    $this->{logger}->logError("Error writing $landed")
      if $this->{zip}->writeToFileNamed("$this->{path}$landed");

    # attach result
    if ( $this->{params}->{outwebtopic} && $this->{params}->{outattachment} ) {
        my $attachment = "$this->{path}$landed";
        my ( $outweb, $outtopic ) = Foswiki::Func::normalizeWebTopicName( undef, $this->{params}->{outwebtopic} );
        my $size = -s $attachment;
        try {
            if ( !Foswiki::Func::topicExists( $outweb, $outtopic) ) {
                my $meta = undef; # TODO
                Foswiki::Func::saveTopic( $outweb, $outtopic, $meta, '%MAKETEXT{"ISO Export"}%' );
            }
            my $outattachment = $this->{params}->{outattachment};
            Foswiki::Func::saveAttachment( $outweb, $outtopic, $outattachment, { file => $attachment, filesize => $size } );
            $this->{logger}->logInfo( "Attached CD image to", "<a href='$Foswiki::cfg{PubUrlPath}/$outweb/$outtopic/$outattachment'>$outattachment</a>" );
        } otherwise {
            my $e = shift;
            Foswiki::Func::writeWarning( $e );
            $this->{logger}->logError( $e );
        };
    }

    return $landed;
}

sub notIncludedLink {
    my ($this, $web, $path, $params, $anchor) = @_;

    unless ( $this->{zipped}->{"$web/_NotIncluded.html"}  ) {
        $this->addString(Foswiki::Func::expandCommonVariables(<<HTML, $web), "$web/_NotIncluded.html");
<html><head><title>Published</title></head><body>%NOTINCLUDEDMESSAGE{default="<h1>%MAKETEXT{"Unfortunately the link you clicked is not available in this export."}%</h1>"}%</body></html>
HTML
    }

    return File::Spec->abs2rel("$web/_NotIncluded", $web).".html?$path$params$anchor";
}


1;
