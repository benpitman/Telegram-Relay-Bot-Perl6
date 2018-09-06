#!/usr/bin/perl6

use v6;

need Repository::AbstractRepository;

class MessageLinkRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => 'message_links');
    }
}
