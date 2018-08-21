#!/usr/bin/perl6

use v6;

need Entity::Entity;

class MessageEntity is Entity
{
    has $.messageHeader is rw = '';
    has $.messageBody is rw = '';
    has $.messageFooter is rw = '';

    method sendMessage ()
    {
        if ?$!messageHeader or ?$!messageBody {
            return True;
        }

        return False;
    }

    method getMessage ()
    {
        return qq:to/MESSAGE/
            $!messageHeader
            $!messageBody
            $!messageFooter
        MESSAGE
    }
}
