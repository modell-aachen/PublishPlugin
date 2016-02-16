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
# PDF writer module for PublishPlugin
#

package Foswiki::Plugins::PublishPlugin::BackEnd::pdf;

use strict;
use Foswiki::Plugins::PublishPlugin::BackEnd::file;
our @ISA = ('Foswiki::Plugins::PublishPlugin::BackEnd::file');
use Error qw( :try );

use constant DESCRIPTION =>
'PDF file with all content in it. Each topic will start on a new page in the PDF.';

use File::Path;

sub new {
    my $class = shift;
    my ($params) = @_;
    $params->{outfile} ||= "pdf";
    my $this = $class->SUPER::new(@_);
    return $this;
}

sub param_schema {
    my $class = shift;
    return {
        outfile => {
            default => 'pdf',
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
        firstpage => {
            default => '%URLS%'
        },
        %{ $class->SUPER::param_schema() }
    };
}

sub close {
    my $this = shift;

    # Create index.html
    my $index = $this->_createIndex( \@{ $this->{urls} } );
    $this->addString( $index, 'index.html' );

    # Make the path to the publish dir
    my $dir = $this->{path};
    eval { File::Path::mkpath($dir) };
    die $@ if ($@);

    # Get a list of temporaries, generated by the superclass
    my $tmpdir = "$dir$this->{params}->{outfile}";
    my @files = map { "$tmpdir/$_" }
      grep { /\.html$/ } @{ $this->{files} };

    my $cmd = $Foswiki::cfg{PublishPlugin}{PDFCmd};
    die "{PublishPlugin}{PDFCmd} not defined" unless $cmd;

    my $landed = $this->{params}->{outfile} . '.pdf';
    my @extras = split( /\s+/, $this->{extras} || '' );

    $ENV{HTMLDOC_DEBUG} = 1;    # see man htmldoc - goes to apache err log
    $ENV{HTMLDOC_NOCGI} = 1;    # see man htmldoc

    $this->{path} .= '/' unless $this->{path} =~ m#/$#;
    my ( $data, $exit ) = Foswiki::Sandbox::sysCommand(
        $Foswiki::sharedSandbox,
        $cmd,
        FILE   => "$this->{path}$landed",
        FILES  => \@files,
        EXTRAS => \@extras
    );

    # htmldoc failsa lot, so log rather than dying
    $this->{logger}->logError("htmldoc failed: $exit/$data/$@") if $exit;

    # Get rid of the temporaries
    File::Path::rmtree($tmpdir);

    if($this->{params}->{catpdf}) {
        Foswiki::Sandbox::sysCommand(
            $Foswiki::sharedSandbox,
            "mv %TOPICS|F% %TMP|F%",
            TOPICS => "$this->{path}$landed",
            TMP => "$this->{path}tmp.pdf"
        );
        my @catfiles;
        foreach my $file (split('\s*,\s*',$this->{params}->{catpdf})) {
            my ($wt, $fname) = $file =~ m#(.*)/(.*)#;
            my ($fweb, $ftopic) = Foswiki::Func::normalizeWebTopicName(undef, $wt);
            unshift(@catfiles, "$Foswiki::cfg{PubDir}/$fweb/$ftopic/$fname");
        }
        unshift(@catfiles, "$this->{path}tmp.pdf");
        Foswiki::Sandbox::sysCommand(
            $Foswiki::sharedSandbox,
            "pdfunite %FILES|F% %FILE|F%",
            FILES => \@catfiles,
            FILE => "$this->{path}$landed"
        );
    }

    # attach result
    if ( $this->{params}->{outwebtopic} && $this->{params}->{outattachment} ) {
        my $attachment = "$this->{path}$landed";
        my ( $outweb, $outtopic ) = Foswiki::Func::normalizeWebTopicName( undef, $this->{params}->{outwebtopic} );
        my $size = -s $attachment;
        try {
            if ( !Foswiki::Func::topicExists( $outweb, $outtopic) ) {
                my $meta = undef; # TODO
                Foswiki::Func::saveTopic( $outweb, $outtopic, $meta, '%MAKETEXT{"PDF Export"}%' );
            }
            my $outattachment = $this->{params}->{outattachment};
            Foswiki::Func::saveAttachment( $outweb, $outtopic, $outattachment, { file => $attachment, filesize => $size } );
            $this->{logger}->logInfo( "Attached pdf to", "<a href='$Foswiki::cfg{PubUrlPath}/$outweb/$outtopic/$outattachment'>$outattachment</a>" );
        } otherwise {
            my $e = shift;
            Foswiki::Func::writeWarning( $e );
            $this->{logger}->logError( $e );
        };
    }

    return $landed;
}

sub _createIndex {
    my $this     = shift;
    my $filesRef = shift;       #( \@{$this->{files}} )
    my $html     = << "HERE";
<!DOCTYPE html>
<html>
<head>
<style type="text/css" media="all">
html body {
        font-size:104%; /* to change the site's font size, change .foswikiPage below */
        voice-family:"\\"}\\"";
        voice-family:inherit;
        font-family:arial, verdana, sans-serif;
        font-size:small;
}
</style>
</head>
<body>
$this->{params}->{firstpage}
</body>
</html>
HERE

    my $urls = join(
        "\n",
        map {
                "<a href='$_'>$_</a></br>"
        } grep { !/^(?:index.html|default.htm)$/ } @$filesRef
    );

    $html =~ s/%URLS%/$urls/;

    return $html;
}

1;
