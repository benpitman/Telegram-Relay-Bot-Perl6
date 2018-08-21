#!/usr/bin/perl6

use v6;

need Module::Message::MessageRepository;
need Module::Message::Entity::MessageEntity;
need Module::Message::Entity::MessageRequestEntity;
need Module::Message::Entity::MessageResponseEntity;

class MessageService
{
    method insert ($messageId, $userId, $chatId, $toMessageId, $stickerId, $documentId, $messageText, $messageDate)
    {
        my $messageRepository = MessageRepository.new;
        return $messageRepository.insert(
            %(
                message_id      => $messageId,
                user_id         => $userId,
                chat_id         => $chatId,
                to_message_id   => $toMessageId,
                sticker_id      => $stickerId,
                document_id     => $documentId,
                message_text    => $messageText,
                message_date    => $messageDate
            )
        );
    }

    method getOneByMessageId ($messageId, $chatId)
    {
        my $messageRepository = MessageRepository.new;

        $messageRepository.select();

        $messageRepository.where(['message_id', 'chat_id'], [$messageId, $chatId]);

        return $messageRepository.getFirst();
    }

    method parseCommand (Str $text, Cool $userId)
    {
        grammar COMMAND {
            token TOP { ^ '/' <command> [\s+]? [ <params> [ \s+ <params> ]* ]? }

            proto token command {*}
            token command:sym<get>  { <sym> }
            token command:sym<set>  { <sym> }

            token params { \w+ }
        }

        my $entity = MessageEntity.new;
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
                        my $messageResponseEntity = MessageResponseEntity.new;

                        $messageResponseEntity.messageHeader = 'Your user ID is:' ~ $userId;
                        return $messageResponseEntity;
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
}
