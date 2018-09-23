#!/usr/bin/perl6

use v6;

need Module::Command::Entity::CommandEntity;

class CommandResponseEntity is CommandEntity
{
    has $!responseType = '';
    has @!responseTypes = (
        'SET_LINK'
    );

    method getResponseTypes ()
    {
        return @!responseTypes;
    }

    method getResponseType ()
    {
        return $!responseType;
    }

    method setResponseType (Str $responseType)
    {
        $!responseType = $responseType if self.isAResponseType($responseType);
    }

    method isAResponseType (Str $responseType)
    {
        return ?@!responseTypes.join.contains($responseType);
    }

    method hasAReponseType ()
    {
        return ?$!responseType;
    }
}
