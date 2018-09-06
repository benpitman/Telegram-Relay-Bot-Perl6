#!/usr/bin/perl6

use v6;

need Repository::AbstractRepository;

class ChatLinkRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => 'chat_links');
    }
}
