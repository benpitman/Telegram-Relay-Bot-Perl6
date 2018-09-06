#!/usr/bin/perl6

use v6;

class ApiDBService
{
    has $!db = 'DB/';

    submethod BUILD (:$!db) {}

    method getUpdateId ()
    {
        return;
    }
}
