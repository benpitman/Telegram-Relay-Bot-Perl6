#!/usr/bin/perl6

use v6;
use Api::ApiService;
use Text::TextService;

class Service
{
    method getApiService ()
    {
        return ApiService;
    }

    method getTextService ()
    {
        return TextService;
    }
}
