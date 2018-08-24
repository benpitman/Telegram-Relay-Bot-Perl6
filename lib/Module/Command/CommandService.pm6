#!/usr/bin/perl6

use v6;
use JSON::Fast;

need Service::Service;

need Module::Command::Entity::CommandEntity;
need Module::Command::Entity::CommandResponseEntity;
need Module::Command::Entity::CommandRequestEntity;

class CommandService
{
    method parseCommand (Str $text, Cool $userId)
    {
        grammar COMMAND {
            token TOP { ^ '/' <command> [\s+]? [ <params> [ \s+ <params> ]* ]? }

            proto token command {*}
            token command:sym<get>  { <sym> }
            token command:sym<set>  { <sym> }

            token params { \w+ }
        }

        my $entity = CommandEntity.new;
        my $commandString = COMMAND.parse($text.lc);

        if !$commandString {
            $entity.messageHeader = "Command '" ~ $text ~ "' not found";
            return $entity;
        }

        my $command = $commandString<command>.Str;
        my @params = $commandString<params>.words;

        given $command {
            when 'get' {
                if @params.elems == 0 {
                    $entity.messageHeader = "Command '/get' requires at least one parameter";
                    return $entity;
                }

                given @params[0] {
                    when 'me' {
                        my $commandResponseEntity = CommandResponseEntity.new;

                        $commandResponseEntity.messageHeader = 'Your user ID is: ' ~ $userId;
                        return $commandResponseEntity;
                    }
                    default {
                        $entity.messageHeader = "Unknown parameter to command '/get'";
                    }
                }

                return $entity;
            }

            when 'set' {
                if @params.elems == 0 {
                    $entity.messageHeader = "Command '/set' requires at least one parameter";
                    return $entity;
                }

                given @params[0] {
                    when 'admin' {
                        my $commandRequestEntity = CommandRequestEntity.new;

                        $commandRequestEntity.messageHeader = 'Please provide my bot token to validate';
                        my $markup = %(
                            force_reply => True
                        );
                        $commandRequestEntity.replyMarkup = to-json($markup);
                        $commandRequestEntity.setRequestType('SET_ADMIN');
                        return $commandRequestEntity;
                    }

                    when 'default' {
                        $entity.setData();
                    }

                    when 'origin' {
                        $entity.setData();
                    }

                    when 'target' {
                        $entity.setData();
                    }
                }

                return $entity;
            }
        }
    }

    method parseResponse (Str $requestType, Str $text, Cool $userId)
    {
        my $entity = CommandEntity.new;

        if !$entity.isARequestType($requestType) {
            $entity.addError("Unknown request type '$requestType'. Internal Error");
            return $entity;
        }

        given $requestType {
            when 'SET_ADMIN' {
                my $service = Service.new;

                if $service.isAdmin($userId) {
                    $entity.messageHeader = 'You are already the admin';
                    return $entity;
                }

                if $service.adminExists() {
                    $entity.messageHeader = 'The admin is already set';
                    return $entity;
                }

                if $text !== $service.getBotToken() {
                    $entity.messageHeader = 'Bot token is invalid';
                    return $entity;
                }

                $service.setAdmin($userId);
                $entity.messageHeader = 'Admin set';

                return $entity;
            }
        }
    }
}
