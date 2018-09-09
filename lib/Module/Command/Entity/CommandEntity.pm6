#!/usr/bin/perl6

use v6;

need Entity::Entity;

class CommandEntity is Entity
{
    has $.messageHeader is rw = '';
    has $.messageBody is rw = '';
    has $.messageFooter is rw = '';
    has $!requestType = '';
    has @!requestTypes = (
        'SET_ADMIN'
    );

    method getRequestTypes ()
    {
        return @!requestTypes;
    }

    method getRequestType ()
    {
        return $!requestType;
    }

    method setRequestType (Str $requestType)
    {
        $!requestType = $requestType if self.isARequestType($requestType);
    }

    method isARequestType (Str $requestType)
    {
        return @!requestTypes.join.contains($requestType);
    }

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
}
