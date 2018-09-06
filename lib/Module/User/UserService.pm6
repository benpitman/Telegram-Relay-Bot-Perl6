#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::User::UserRepository;

class UserService
{
    method insert ($userId, $isBot, $forename, $surname, $username)
    {
        my $userRepository = UserRepository.new;

        return $userRepository.insert(
            %(
                user_id         => $userId,
                user_bot        => +$isBot,
                user_forename   => $forename,
                user_surname    => $surname,
                user_username   => $username
            )
        );
    }

    method getOneByUserId ($userId)
    {
        my $userRepository = UserRepository.new;

        $userRepository.select();

        $userRepository.where('user_id', $userId);

        return $userRepository.getFirst();
    }

    method getName ($Id)
    {
        my $userRepository = UserRepository.new;

        $userRepository.select();

        $userRepository.where('ID', $Id);

        my Entity $entity = $userRepository.getFirst();

        return $entity if $entity.hasErrors();

        my %user = $entity.getData();
        my $name = '';

        if ?%user<user_forename> {
            $name ~= %user<user_forename> ~ ' ';
        }

        if ?%user<user_surname> {
            $name ~= %user<user_surname> ~ ' ';
        }

        if ?$name && ?%user<user_username> {
            $name ~= '(@' ~ %user<user_username> ~ ')';
        }

        $entity.setData($name);
        return $entity;
    }
}
