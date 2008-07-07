package Foo;

use 5.010;

our $VERSION = 1;

sub import {
    say "Foo::import($_)" foreach @_;
}

sub unimport {
    say "Foo::unimport($_)" foreach @_;
}

1;
