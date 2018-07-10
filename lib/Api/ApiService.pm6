#!/usr/bin/perl6

use v6;
use Api::ApiHttpService;
use Entity::Entity;

class ApiService
{
    has %.apiConfig;

    has $!apiHttpService = ApiHttpService.new;
    has $!entity = Entity.new;
    has $!token = %!apiConfig<token>;
    has $!url = 'http://fjeodfneodmeiowmdiowe.com';
    has %!post = %();

    method getUpdates ()
    {
        # my $url = "https://api.telegram.org/bot" ~ $!token ~ "/getUpdates";
        my %post = %(user => 'name', pass => 'word');

        my Str $post = ~%!post
            .subst( /\n/, '&', :g )
            .subst( /\h+/, '=', :g );
        # say S:g[\h+] = '=' with ( S[\n] = '&' with ~%a );

        my Entity $httpEntity = $!apiHttpService.post($!url);

        $!entity.addError($httpEntity.getErrors()) if $httpEntity.hasErrors();
        return $!entity;
    }
}
