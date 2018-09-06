#!/usr/bin/perl6

use v6;

need Repository::AbstractRepository;

class ResponseRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => 'responses');
    }
}
