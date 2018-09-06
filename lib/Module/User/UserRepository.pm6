#!/usr/bin/perl6

use v6;

need Repository::AbstractRepository;

class UserRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => 'users');
    }
}
