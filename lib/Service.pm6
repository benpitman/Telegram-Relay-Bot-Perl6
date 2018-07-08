#!/usr/bin/perl6

use v6;
use Api::ApiService;

class Service
{
    method getApiService ()
    {
        return ApiService;
    }
}
