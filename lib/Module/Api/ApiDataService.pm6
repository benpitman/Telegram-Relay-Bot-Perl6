#!/usr/bin/perl6

use v6;
use JSON::Tiny;

need Entity::Entity;

need Module::User::UserService;
need Module::Chat::ChatService;
need Module::Message::MessageService;

class ApiDataService
{
    has $!entity = Entity.new;
    has %!result;

    method parseResponse (Str $response)
    {
        my %response = from-json($response);

        if !%response<ok> {
            $!entity.addError('(' ~ %response<error_code> ~ '): ' ~ %response<description>);
            return $!entity;
        }

        # Result can be array or hash, this makes sure it's always a 1D array
        my @results;
        given %response<result> {
            when Hash { @results = [$_]; }
            when Array { @results = |$_; }
        }
        # say @results[0].WHAT;exit;
        # @results if @results[0].WHAT === Array;
        my $updateId;
        my $userService = UserService.new;
        my $chatService = ChatService.new;
        my $messageService = MessageService.new;

        for @results -> %result {

            # Overwrite every time so it's set to the last in the loop
            $updateId = %result<update_id>;
            my %message = %result<message>;

            my %from = %message<from>;
            my Entity $userEntity = $userService.insert(
                %from<id>,
                %from<is_bot>,
                %from<first_name>   // '',
                %from<last_name>    // '',
                %from<username>     // ''
            );

            if $userEntity.hasErrors() {
                $!entity.addError($userEntity.getErrors());
                return $!entity;
            }

            my %chat = %message<chat>;
            my Entity $chatEntity = $chatService.insert(
                %chat<id>,
                %chat<title>,
                %chat<type>
            );

            if $chatEntity.hasErrors() {
                $!entity.addError($chatEntity.getErrors());
                return $!entity;
            }

            my Entity $messageEntity = $messageService.insert(
                %message<message_id>,
                $userEntity.getData()[0],
                $chatEntity.getData()[0],
                Any, #TODO Need to allow NULL
                DateTime.new(%message<date>),
                %message<text> // ''
            );

            if $messageEntity.hasErrors() {
                $!entity.addError($messageEntity.getErrors());
                return $!entity;
            }

            say $updateId; exit;
        }
    }
}
