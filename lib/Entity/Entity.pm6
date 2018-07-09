#!/usr/bin/perl6

use v6;

class Entity
{
    has @!errors;

    method hasErrors ()
    {
        return ?@!errors;
    }

    multi method addError (Array \errors)
    {
        return if !errors.elems;
        @!errors.append: errors;
    }

    multi method addError (Str \error)
    {
        return if ?error == '';
        @!errors.push: error;
    }

    method getErrors ()
    {
        return @!errors;
    }
}
