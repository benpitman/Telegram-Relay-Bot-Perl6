#!/usr/bin/perl6

use v6;

need Repository::AbstractRepository;

class RequestRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => 'requests');
    }
}
