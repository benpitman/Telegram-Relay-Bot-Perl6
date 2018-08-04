#!/usr/bin/perl6

use v6;
use lib <lib>;
use App;

sub MAIN ()
{
    my $app = App.new;
    $app.init();
}
