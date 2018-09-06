#!/usr/bin/perl6

use v6;

need Repository::AbstractRepository;

class MessageRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => 'messages');
    }
}
