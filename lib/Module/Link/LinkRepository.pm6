#!/usr/bin/perl6

use v6;

need Repository::AbstractRepository;

class LinkRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => 'links');
    }
}
