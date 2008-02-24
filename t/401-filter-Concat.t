#!perl -w

use strict;

my $digest = "b11bf9a77b520852e95af3e0b5c1aa95";

use Test::More qw/no_plan/;

use t::Test;
my $assets = t::Test->assets(
    filters => [
        File::Assets::Filter::Concat->new(fit => "css"),
    ],
    output_path => [
        [ "css-screen" => $digest ],
    ],
);
my $scratch = t::Test->scratch;

$assets->include("css/apple.css");
$assets->include("css/banana.css");
$assets->include("js/apple.js");

is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/$digest.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_

ok($scratch->exists("static/$digest"));
ok(-s $scratch->file("static/$digest"));
is($scratch->read("static/$digest"), <<_END_);
/* Test file: static/css/apple.css */

/* Test file: static/css/banana.css */
_END_

#ok($assets->filter([ "concat" => type => ".css", output => '%D.%e', ]));
#is($assets->export, <<_END_);
#<link rel="stylesheet" type="text/css" href="http://example.com/static/$digest.css" />
#<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
#_END_

#ok($scratch->exists("static/$digest.css"));
#ok(-s $scratch->file("static/$digest.css"));
