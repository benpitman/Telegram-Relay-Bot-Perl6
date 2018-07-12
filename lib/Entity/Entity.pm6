#!/usr/bin/perl6

use v6;
use JSON::Tiny;

class Entity
{
    has %!response = %(
        data    => Any,
        errors  => []
    );

    method setData (Any \data)
    {
        %!response<data> = data;
    }

    method getData ()
    {
        return %!response<data>;
    }

    method hasErrors ()
    {
        return ?%!response<errors>;
    }

    multi method addError (Array \errors)
    {
        %!response<errors>.append: errors.flat if ?errors.elems;
    }

    multi method addError (Str \error)
    {
        %!response<errors>.push: error if ?error !== '';
    }

    method getErrors ()
    {
        return %!response<errors>;
    }

    method dispatch ()
    {
        say to-json(%!response);
    }
}
