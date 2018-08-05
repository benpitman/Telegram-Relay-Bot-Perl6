#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::Message::MessageEntity;
need Module::Message::MessageRepository;

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
}
