#!/usr/bin/perl6

use v6;

need Module::Command::Entity::CommandEntity;

class CommandRequestEntity is CommandEntity
{
    has $.replyMarkup is rw = '{}';

    method hasMarkup ()
    {
        return ?$!replyMarkup;
    }

    method getMarkup ()
    {
        return $!replyMarkup;
    }
}
