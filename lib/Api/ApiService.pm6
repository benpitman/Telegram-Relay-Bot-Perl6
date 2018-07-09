#!/usr/bin/perl6

use v6;
use Api::ApiHttpService;
use Entity::Entity;

class ApiService
{
    has %.apiConfig;
    has $!token = %!apiConfig<token>;
    has $!apiHttpService = ApiHttpService.new;
    has $!entity = Entity.new;

    method getUpdates ()
    {
        $!apiHttpService.connect();
        return $!entity;
    }
}
