#!/usr/bin/env perl

use 5.008001;
use utf8;
use strict;
use warnings;

use version; our $VERSION = qv('v1.0.0');

use Module::Used qw< modules_used_in_string >;

use Test::Deep qw< bag cmp_deeply >;
use Test::More tests => 6;


my $code;


$code = 'use strict;';
cmp_deeply(
    [ modules_used_in_string( $code ) ],
    [ qw< strict > ],
    $code,
);


$code = 'use 5.006;';
cmp_deeply(
    [ modules_used_in_string( $code ) ],
    [],
    $code,
);


$code = <<'END_CODE';
    use A;
    require B;
    no C;
END_CODE

cmp_deeply(
    [ modules_used_in_string( $code ) ],
    bag( qw< A B C > ),
    'use require no',
);


$code = q<use base 'A', "B", q[C], qq[D::E];>;
cmp_deeply(
    [ modules_used_in_string( $code ) ],
    bag( qw< A B C D::E base > ),
    $code,
);


$code = q<use parent 'A', qw[ B C D::E ];>;
cmp_deeply(
    [ modules_used_in_string( $code ) ],
    bag( qw< A B C D::E parent > ),
    $code,
);


$code = q<use base 2.13 'A';>;
cmp_deeply(
    [ modules_used_in_string( $code ) ],
    bag( qw< A base > ),
    $code,
);

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
