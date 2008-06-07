package File::Assets::Filter::Minifier::CSS::XS;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier::Base/;
use File::Assets::Carp;

sub minify {
    return CSS::Minifier::XS::minify(shift);
}

1;
