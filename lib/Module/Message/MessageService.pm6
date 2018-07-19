#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::Message::MessageEntity;
need Module::Message::MessageRepository;

class MessageService
{
    has $!entity = MessageEntity.new;

    method insert ()
    {
        my $messageRepository = MessageRepository.new;
        my Entity $messageEntity = $messageRepository.insertNew();

        if $messageEntity.hasErrors() {
            $!entity.addError($messageEntity.getErrors());
            return $!entity;
        }
    }

    method get ()
    {
        #TODO Perl seems to automatically flatten multidimensional arrays.

        =begin comment
        # INSERT
        # WHERE column = 0
        where([column => 0]);
        where({column => 0});
        where('column', '=', 0);

        # WHERE columnA = 1 AND columnB = 2
        where({columnA => 1, columnB => 2});
        where(['columnA', 'columnB'], [1, 2]);
        where(['columnA', 'columnB'], ['=', '='], [1, 2]);

        # WHERE (columnA = 1 AND columnB = 2) OR columnC = 3
        where([{columnA => 1, columnB => 2}, {columnC => 3}]);
        where(['columnA', 'columnB'], [1, 2]);
            orWhere(['columnC'], [3]);
        where(['columnA', 'columnB'], ['=', '='], [1, 2]);
            orWhere(['columnC'], ['='], [3]);
        =end comment
        =cut

        my $messageRepository = MessageRepository.new;
        $messageRepository.select(['id', 'date']);
        # $messageRepository.insert(['name', 'date'], ['hello', DateTime.now]);
        # $messageRepository.where([%(id => 19, name => 'newtest'),%(id => 21)]);
        # $messageRepository.where([%(id => 19, name => 'newtest'),%(id => 21)]);
        # $messageRepository.where([['id', '=', 19], ['name', '=', 'newtest']]);
        # $messageRepository.where([a => 1]);
        # $messageRepository.where(['a', 'b'], ['>'], [1, 2]);
        # $messageRepository.where(['a', 'b'], [1, 2]);
        # $messageRepository.where(['a'], [1]);
        # $messageRepository.where([{columnA => 1, columnB => 2}, {columnC => 3}]);
        # $messageRepository.where([['id', '=', 21]]);
        # $messageRepository.where({id => 19, name => 'newtest'});
        # $messageRepository.where({id => 19});
        my Entity $messageEntity = $messageRepository.get();
        say $messageRepository.all();
        exit;
        $messageEntity.dispatch();
    }
}
