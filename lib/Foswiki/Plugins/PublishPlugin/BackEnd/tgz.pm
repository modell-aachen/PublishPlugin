#
# Copyright (C) 2005-2009 Crawford Currie, http://c-dot.co.uk
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
package Foswiki::Plugins::PublishPlugin::BackEnd::tgz;

use strict;

use Foswiki::Plugins::PublishPlugin::BackEnd;
our @ISA = ('Foswiki::Plugins::PublishPlugin::BackEnd');

use constant DESCRIPTION =>
  'HTML compressed into a single tgz archive for shipping.';

use Foswiki::Func;
use File::Path;
use Assert;

sub new {
    my $class = shift;
    my ($params) = @_;
    $params->{outfile} ||= "tgz";
    my $this = $class->SUPER::new(@_);

    require Archive::Tar;
    $this->{tar} = Archive::Tar->new();

    return $this;
}

sub param_schema {
    my $class = shift;
    return {
        outfile => {
            default => 'tgz',
            validator =>
              \&Foswiki::Plugins::PublishPlugin::Publisher::validateFilename
        },
        outwebtopic => {
            default => ''
        },
        outattachment => {
            default => ''
        },
        %{ $class->SUPER::param_schema() }
    };
}

sub addString {
    my ( $this, $string, $file ) = @_;
    unless ( $this->{tar}->add_data( $file, $string ) ) {
        $this->{logger}->logError( $this->{tar}->error() );
    }
}

sub addFile {
    my ( $this, $from, $to ) = @_;
    my $fh;
    if ( open( $fh, '<', $from ) ) {
        local $/;
        binmode($fh);
        my $contents = <$fh>;
        $this->addString( $contents, $to );
        close($fh);
    }
    else {
        $this->{logger}->logError("Failed to open $from: $!");
    }
}

sub close {
    my $this = shift;
    my $dir  = $this->{path};
    eval { File::Path::mkpath($dir) };
    $this->{logger}->logError($@) if $@;
    my $landed = "$this->{params}->{outfile}.tgz";
    unless ( $this->{tar}->write( "$this->{path}$landed", 1 ) ) {
        $this->{logger}->logError( $this->{tar}->error() );
    }
    # attach result
    if ( $this->{params}->{outwebtopic} && $this->{params}->{outattachment} ) {
        my $attachment = "$this->{path}$landed";
        my ( $outweb, $outtopic ) = Foswiki::Func::normalizeWebTopicName( undef, $this->{params}->{outwebtopic} );
        my $size = -s $attachment;
        try {
            if ( !Foswiki::Func::topicExists( $outweb, $outtopic) ) {
                my $meta = undef; # TODO
                Foswiki::Func::saveTopic( $outweb, $outtopic, $meta, '%MAKETEXT{"TGZ Export"}%' );
            }
            my $outattachment = $this->{params}->{outattachment};
            Foswiki::Func::saveAttachment( $outweb, $outtopic, $outattachment, { file => $attachment, filesize => $size } );
            $this->{logger}->logInfo( "Attached tgz to", "<a href='$Foswiki::cfg{PubUrlPath}/$outweb/$outtopic/$outattachment'>$outattachment</a>" );
        } otherwise {
            my $e = shift;
            Foswiki::Func::writeWarning( $e );
            $this->{logger}->logError( $e );
        };
    }

    return $landed;
}

1;
