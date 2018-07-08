#!/usr/bin/perl6

use v6;
use Api::ApiHttpService;

class ApiService
{
    has %.apiConfig;
    has $!token = %!apiConfig<token>;
    has $!apiHttpService = ApiHttpService.new;

    method getUpdates ()
    {
        return $!apiHttpService.connect();
    }
}
