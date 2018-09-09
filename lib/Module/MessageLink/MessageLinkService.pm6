#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::MessageLink::MessageLinkRepository;

class MessageLinkService
{
    method insert (Cool $originMessageId, Cool $targetMessageId)
    {
        my $messageLinkRepository = MessageLinkRepository.new;

        return $messageLinkRepository.insert(
            %(
                'message_link_origin_message_id'    => $originMessageId,
                'message_link_target_message_id'    => $targetMessageId
            )
        );
    }

    method getOneByOrigin (Cool $messageId)
    {
        my $messageLinkRepository = MessageLinkRepository.new;

        $messageLinkRepository.select();

        $messageLinkRepository.where('message_link_origin_message_id', $messageId);

        return $messageLinkRepository.getFirst();
    }

    method getMessageLink ($messageId)
    {
        my $entity = Entity.new;
        my $messageLinkRepository = MessageLinkRepository.new;

        $messageLinkRepository.select();

        $messageLinkRepository.where('message_link_origin_message_id', $messageId);
        $messageLinkRepository.orWhere('message_link_target_message_id', $messageId);

        my Entity $messageLinkEntity = $messageLinkRepository.getFirst();

        return $messageLinkEntity if $messageLinkEntity.hasErrors();

        if $messageLinkEntity.getData()<message_link_origin_message_id> === $messageId {
            $entity.setData($messageLinkEntity.getData()<message_link_target_message_id>);
        }
        else {
            $entity.setData($messageLinkEntity.getData()<message_link_origin_message_id>);
        }

        return $entity;
    }
}
