#!/usr/bin/perl6

use v6;
use Entity::Entity;
use JSON::Tiny;

class ApiDataService
{
    has $!entity = Entity.new;
    has %!result;

    method parseResponse (@results)
    {
        my $updateId;

        for @results -> %response {
            %response.map: {

                %!result.push: %(
                    updateId    => %^item<update_id>,
                    message     => %(
                        %^item<message>
                    )
                );

                say to-json(%^item);
                say "\n";

                # Overwrite every time so it's set to the last in the loop
                $updateId = %^item<update_id>;
            }

            die $updateId;
        }
    }
}
