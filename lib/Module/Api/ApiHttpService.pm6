#!/usr/bin/perl6

use v6;
use JSON::Tiny;
use LibCurl::HTTP; # requires libcurl4-openssl-dev

need Entity::Entity;

class ApiHttpService
{
    has $!http = LibCurl::HTTP.new;
    has $!entity = Entity.new;

    method post (Str \url, Str \post = '')
    {
        try {
            $!http.POST(url, post).perform;

            CATCH {
                when X::LibCurl {
                    $!entity.addError("$_.Int() : $_");
                    $!entity.addError($!http.error);
                    return $!entity;
                }
            }
        }

        my $response = $!http.content;
        try {
            from-json($response);

            CATCH {
                $!entity.addError("$_");
                return $!entity;
            }
        }

        $!entity.setData($response);
        return $!entity;
    }
}
