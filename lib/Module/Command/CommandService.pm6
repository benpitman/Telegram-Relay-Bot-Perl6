#!/usr/bin/perl6

use v6;
use JSON::Fast;

need Service::Service;

need Module::Command::Entity::CommandEntity;
need Module::Command::Entity::CommandResponseEntity;
need Module::Command::Entity::CommandRequestEntity;

need Module::ChatLink::ChatLinkService;
need Module::Request::RequestService;

class CommandService
{
    grammar COMMAND {
        token TOP { ^ '/' <command> [\s+]? [ <params> [ \s+ <params> ]* ]? }

        proto token command {*}
        token command:sym<start>    { <sym> }
        token command:sym<get>      { <sym> }
        token command:sym<set>      { <sym> }
        token command:sym<cancel>   { <sym> }
        token command:sym<unset>    { <sym> }

        token params { \w+ }
    }

    method parseCommand (Str $text, Cool $chatId, Cool $userId, Bool $isPrivate = False)
    {
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
                $entity.setCommandSuccess();
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
                        $commandResponseEntity.setCommandSuccess();

                        return $commandResponseEntity;
                    }

                    default {
                        $entity.messageHeader = "Unknown parameter to command '/get'";
                    }
                }
            }

            when 'set' {
                if @params.elems == 0 {
                    $entity.messageHeader = "Command '/set' requires at least one parameter";
                    return $entity;
                }

                my $service = Service.new;

                given @params[0] {
                    when 'admin' {
                        if !$isPrivate {
                            $entity.messageHeader = 'This command can only be used in a private chat';
                            return $entity;
                        }

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
                        $commandRequestEntity.markupForceReply();
                        $commandRequestEntity.setRequestType('SET_ADMIN');
                        $commandRequestEntity.setCommandSuccess();

                        return $commandRequestEntity;
                    }

                    when 'default' {
                        if !$service.isAdmin($userId) {
                            $entity.messageHeader = 'You do not have permission to use this command';
                            return $entity;
                        }

                        if $service.isDefaultTargetChatId($chatId) {
                            $entity.messageHeader = 'This chat is already the default';
                            return $entity;
                        }

                        $service.setDefaultTargetChatId($chatId);
                        my $commandResponseEntity = CommandResponseEntity.new;

                        $commandResponseEntity.messageHeader = 'Default target chat set';
                        $commandResponseEntity.setCommandSuccess();

                        return $commandResponseEntity;
                    }

                    when 'origin' {
                        if $isPrivate {
                            $entity.messageHeader = 'You cannot use this command in a public chat';
                            return $entity;
                        }

                        if !$service.isAdmin($userId) {
                            $entity.messageHeader = 'You do not have permission to use this command';
                            return $entity;
                        }

                        if $service.isDefaultTargetChatId($chatId) {
                            $entity.messageHeader = 'This chat is the default, it cannot be an origin';
                            return $entity;
                        }

                        my $chatLinkService = ChatLinkService.new;

                        my $chatLinkEntity = $chatLinkService.getChatLink($chatId);

                        if $chatLinkEntity.hasErrors() {
                            $entity.addError($chatLinkEntity.getErrors());
                            return $entity;
                        }

                        if $chatLinkEntity.hasData() {
                            $entity.messageHeader = 'This chat is already linked to another chat';
                            $entity.messageBody = "Run '/unset link' if you would like to disable this chat link";
                            return $entity;
                        }

                        my $commandRequestEntity = CommandRequestEntity.new;

                        $commandRequestEntity.messageHeader = 'Origin chat set';
                        $commandRequestEntity.messageBody = "Now run '/set target' in a new target chat";
                        $commandRequestEntity.messageFooter = "Or '/cancel' to cancel the last request";
                        $commandRequestEntity.setRequestType('SET_LINK');
                        $commandRequestEntity.setCommandSuccess();

                        return $commandRequestEntity;
                    }

                    when 'target' {
                        if !$service.isAdmin($userId) {
                            $entity.messageHeader = 'You do not have permission to use this command';
                            return $entity;
                        }

                        if $service.isDefaultTargetChatId($chatId) {
                            $entity.messageHeader = 'This chat is the default';
                            return $entity;
                        }

                        my $requestService = RequestService.new;

                        my $requestEntity = $requestService.getByRequestType($userId, 'SET_LINK');

                        if $requestEntity.hasErrors() {
                            $entity.addError($requestEntity.getErrors());
                            return $entity;
                        }

                        if !$requestEntity.hasData() {
                            $entity.messageHeader = "Command '/set origin' has not been run";
                            return $entity;
                        }

                        my $chatLinkService = ChatLinkService.new;

                        my $chatLinkEntity = $chatLinkService.getChatLink($chatId);

                        if $chatLinkEntity.hasErrors() {
                            $entity.addError($chatLinkEntity.getErrors());
                            return $entity;
                        }

                        if $chatLinkEntity.hasData() {
                            $entity.messageHeader = 'This chat is already linked to another chat';
                            $entity.messageBody = "Run '/unset link' if you would like to disable this chat link";
                            return $entity;
                        }

                        my $commandResponseEntity = CommandResponseEntity.new;

                        $commandResponseEntity.setResponseType('SET_LINK');
                        $commandResponseEntity.setCommandSuccess();

                        return $commandResponseEntity;
                    }

                    default {
                        $entity.messageHeader = "Unknown parameter to command '/set'";
                    }
                }
            }

            when 'cancel' {
                my $requestService = RequestService.new;
                my $commandResponseEntity = CommandResponseEntity.new;

                my $requestEntity = $requestService.cancelLastRequest($userId);

                if $requestEntity.hasErrors() {
                    $entity.addError($requestEntity.getErrors());
                    return $entity;
                }

                $commandResponseEntity.messageHeader = 'Last request cancelled';
                $commandResponseEntity.setCommandSuccess();

                return $commandResponseEntity;
            }

            when 'unset' {
                if @params.elems == 0 {
                    $entity.messageHeader = "Command '/unset' requires at least one parameter";
                    return $entity;
                }

                given @params[0] {
                    when 'default' {
                        my $commandResponseEntity = CommandResponseEntity.new;

                        $commandResponseEntity.messageHeader = '';
                        $commandResponseEntity.setCommandSuccess();

                        return $commandResponseEntity;
                    }

                    when 'link' {
                        my $commandResponseEntity = CommandResponseEntity.new;

                        $commandResponseEntity.messageHeader = '';
                        $commandResponseEntity.setCommandSuccess();

                        return $commandResponseEntity;
                    }
                }
            }
        }

        return $entity;
    }

    method parseResponse (%request, Str $responseType, Str $text, Cool $chatId, Cool $userId)
    {
        my $entity = CommandEntity.new;
        my $commandRequestEntity = CommandRequestEntity.new;
        my $requestType = %request<request_type>;

        if !$commandRequestEntity.isARequestType($requestType) {
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
                $entity.setCommandSuccess();
            }

            when 'SET_LINK' {
                if $responseType ne $requestType {
                    $entity.messageHeader = "'/set target' or '/cancel' must be run to continue functionality";
                    return $entity;
                }

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
                $entity.setCommandSuccess();
            }
        }

        return $entity;
    }
}
