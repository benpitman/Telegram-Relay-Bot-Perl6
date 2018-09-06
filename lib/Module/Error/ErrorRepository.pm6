#!/usr/bin/perl6

use v6;

need Repository::AbstractRepository;

class ErrorRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => 'errors');
    }
}
