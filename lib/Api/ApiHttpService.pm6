#!/usr/bin/perl6

use v6;
use LibCurl::HTTP; # requires libcurl4-openssl-dev

class ApiHttpService
{
    has $http = LibCurl::HTTP.new;

    method connect ()
    {
        my %a = %(user => 'name', pass => 'word');

        ~%a
            .subst( /\n/, '&', :g )
            .subst( /\h+/, '=', :g )
            .say;
        # say S:g[\h+] = '=' with ( S[\n] = '&' with ~%a );
    }
}
