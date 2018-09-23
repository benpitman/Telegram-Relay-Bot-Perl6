#!/usr/bin/perl6

use v6;
use JSON::Fast;

need Module::Command::Entity::CommandEntity;

class CommandRequestEntity is CommandEntity
{
    has $.replyMarkup is rw = '{}';
    has $!requestType = '';
    has @!requestTypes = (
        'SET_ADMIN',
        'SET_LINK'
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
        return ?@!requestTypes.join.contains($requestType);
    }

    method markupForceReply ()
    {
        my %markup = from-json($!replyMarkup);
        %markup<force_reply> = True;

        $!replyMarkup = to-json(%markup);
    }

    method hasMarkup ()
    {
        return ?$!replyMarkup;
    }

    method getMarkup ()
    {
        return $!replyMarkup;
    }
}
