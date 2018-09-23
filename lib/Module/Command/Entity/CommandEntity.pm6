#!/usr/bin/perl6

use v6;

need Entity::Entity;

class CommandEntity is Entity
{
    has $.messageHeader is rw = '';
    has $.messageBody is rw = '';
    has $.messageFooter is rw = '';
    has $!commandSuccess = False;

    method hasMessage ()
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

    method setCommandSuccess (Bool $success = True)
    {
        $!commandSuccess = $success;
    }

    method getCommandSuccess ()
    {
        return ?$!commandSuccess;
    }
}
