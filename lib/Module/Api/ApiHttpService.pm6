#!/usr/bin/perl6

use v6;
use LibCurl::HTTP; # requires libcurl4-openssl-dev
use Entity::Entity;

class ApiHttpService
{
    has $!http = LibCurl::HTTP.new;
    has $!entity = Entity.new;

    method post (Str \url, Str \post = '')
    {
        # try {
        #     $!http.POST(url, post).perform;
        #
        #     CATCH {
        #         when X::LibCurl {
        #             $!entity.addError("$_.Int() : $_");
        #             $!entity.addError($!http.error);
        #             return $!entity;
        #         }
        #     }
        # }
        #
        # $!entity.setData($!http.content) if $!http.success;

        #TODO format errors (description)

        return $!entity;
    }
}
