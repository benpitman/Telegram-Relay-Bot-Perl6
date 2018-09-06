#!/usr/bin/perl6

use v6;

need Repository::AbstractRepository;

class ChatRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => 'chats');
    }
}
