#!/usr/bin/perl6

use v6;
use Entity::Entity;
use JSON::Tiny;

class ApiDataService
{
    has $!entity = Entity.new;

    method parseResponse (Str $json)
    {
        my %response;

        try {
            %response = from-json($json);

            CATCH {
                $!entity.addError("$_");
                return $!entity;
            }
        }

        %response<result>.map: {
            say "$^item\n\n";
            sleep 2;
        }

        die;
    }
}
