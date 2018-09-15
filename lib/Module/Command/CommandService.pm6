#!/usr/bin/perl6

use v6;
use JSON::Fast;

need Service::Service;

need Module::Command::Entity::CommandEntity;
need Module::Command::Entity::CommandResponseEntity;
need Module::Command::Entity::CommandRequestEntity;

need Module::ChatLink::ChatLinkService;

class CommandService
{
    method parseCommand (Str $text, Cool $chatId, Cool $userId, Bool $isPrivate = False)
    {
        grammar COMMAND {
            token TOP { ^ '/' <command> [\s+]? [ <params> [ \s+ <params> ]* ]? }

            proto token command {*}
            token command:sym<start>    { <sym> }
            token command:sym<get>      { <sym> }
            token command:sym<set>      { <sym> }

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
            when 'start' {
                return $entity;
            }

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
                        if !$isPrivate {
                            $entity.messageHeader = 'This command can only be used in a private chat';
                            return $entity;
                        }

                        my $service = Service.new;
                        if $service.isAdmin($userId) {
                            $entity.messageHeader = 'You are already the admin';
                            return $entity;
                        }

                        if $service.adminExists() {
                            $entity.messageHeader = 'The admin is already set';
                            return $entity;
                        }

                        my $commandRequestEntity = CommandRequestEntity.new;

                        $commandRequestEntity.messageHeader = 'Please provide my bot token to validate';
                        my %markup = %(
                            force_reply => True
                        );
                        $commandRequestEntity.replyMarkup = to-json(%markup);
                        $commandRequestEntity.setRequestType('SET_ADMIN');

                        return $commandRequestEntity;
                    }

                    when 'default' {
                        my $service = Service.new;

                        if !$service.isAdmin($userId) {
                            $entity.messageHeader = 'You do not have permission to use this command';
                            return $entity;
                        }

                        if $chatId eq $service.getDefaultTargetChatId() {
                            $entity.messageHeader = 'This chat is already the default';
                            return $entity;
                        }

                        $service.setDefaultTargetChatId($chatId);
                        my $commandResponseEntity = CommandResponseEntity.new;

                        $commandResponseEntity.messageHeader = 'Default target chat set';
                        return $commandResponseEntity;
                    }

                    when 'origin' {
                        my $service = Service.new;

                        if !$service.isAdmin($userId) {
                            $entity.messageHeader = 'You do not have permission to use this command';
                            return $entity;
                        }

                        if $chatId eq $service.getDefaultTargetChatId() {
                            $entity.messageHeader = 'This chat is the default, it cannot be an origin';
                            return $entity;
                        }

                        my $commandRequestEntity = CommandRequestEntity.new;

                        $commandRequestEntity.messageHeader = 'Origin chat set';
                        $commandRequestEntity.messageBody = "Now run '/set target' in a new target chat";
                        $commandRequestEntity.setRequestType('SET_LINK');

                        return $commandRequestEntity;
                    }

                    when 'target' {
                        my $service = Service.new;

                        if !$service.isAdmin($userId) {
                            $entity.messageHeader = 'You do not have permission to use this command';
                            return $entity;
                        }

                        if $chatId eq $service.getDefaultTargetChatId() {
                            $entity.messageHeader = 'This chat is the default';
                            return $entity;
                        }
                    }

                    default {
                        $entity.messageHeader = "Unknown parameter to command '/set'";
                    }
                }

                return $entity;
            }
        }
    }

    method parseResponse (%request, Str $text, Cool $userId, Cool $chatId)
    {
        my $entity = CommandEntity.new;
        my $requestType = %request<request_type>;

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

                if $text ne $service.getBotToken() {
                    $entity.messageHeader = 'Bot token is invalid';
                    return $entity;
                }

                $service.setAdmin($userId);
                $entity.messageHeader = 'Admin set';
            }

            when 'SET_LINK' {
                if $chatId eq %request<request_chat_id> {
                    $entity.messageHeader = 'Origin chat cannot be the same as the target chat';
                    return $entity;
                }

                my $chatLinkService = ChatLinkService.new;

                my $chatLinkEntity = $chatLinkService.insert(
                    %request<request_chat_id>,
                    $chatId
                );

                if $chatLinkEntity.hasErrors() {
                    $entity.addError($chatLinkEntity.getErrors());
                    return $entity;
                }

                $entity.messageHeader = 'Chat link set';
            }
        }

        return $entity;
    }
}
