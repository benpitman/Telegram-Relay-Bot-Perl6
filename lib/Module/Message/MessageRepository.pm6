#!/usr/bin/perl6

use v6;
use DBIish;

need Repository::AbstractRepository;

class MessageRepository does AbstractRepository
{
    method new ()
    {
        self.bless(table => "message");
    }

    method insertNew ()
    {
        my @ids = self.insert(
            [
                %(
                    name    => "newtest",
                    date    => DateTime.now
                ),
                %(
                    namde    => "hello there",
                    date    => DateTime.now
                )
            ]
        );

        $!entity.setData(@ids);

        return $!entity;

    }
}
