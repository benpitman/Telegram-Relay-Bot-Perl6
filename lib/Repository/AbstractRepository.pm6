#!/usr/bin/perl6

use v6;
use DBIish;

need Service::Service;
need Entity::Entity;

role AbstractRepository
{
    has $.table is rw;
    has $!dbc;
    has $!dbs = '';
    has $!dbe;
    has $!entity = Entity.new;

    submethod BUILD (:$!table)
    {
        my %config = Service.getConfig();
        my Str $database = %config<database>.gist;

        $!dbc = DBIish.connect(
            'SQLite',
            database => $database
        ) // die "Database '$database' not found.";
    }

    submethod END ()
    {
        $!dbc.dispose();
        $!dbs.finish();
    }

    multi method insert (@rows)
    {
        my @ids;
        my @id;

        for @rows -> %row {
            @id = self.insert(%row);

            last if $!entity.hasErrors();
            @ids.push: @id[0];
        }

        return @ids;
    }

    multi method insert (%row)
    {
        my @cols;
        my @vals;

        for %row.kv -> $col, $val {
            @cols.push: $col;

            given $val.^name {
                when Int {
                    @vals.push: "$val";
                }
                default {
                    @vals.push: "'$val'";
                }
            }
        }

        my $colString = @cols.join(', ');
        my $valString = @vals.join(', ');

        $!dbs = qq:to/STATEMENT/;
            INSERT INTO $!table ($colString)
            VALUES ($valString)
        STATEMENT

        try {
            $!dbe = $!dbc.prepare($!dbs);
            $!dbe.execute();

            CATCH {
                $!entity.addError("$_");
                return;
            }
        }

        # Get last ID
        my $dbs = $!dbc.prepare("SELECT last_insert_rowid()");
        $dbs.execute();
        my @lastId = $dbs.row();

        $dbs.finish();

        return @lastId;
    }

    method select (@cols)
    {
        my $colString = @cols.join(', ');

        $!dbs = qq:to/STATEMENT/;
        	SELECT $colString
        	FROM $!table
        STATEMENT
    }

    multi method where (%matches)
    {
        my $whereString = '';

        for %matches.kv -> $col, $match {
            FIRST { $whereString ~= "("; }
            $whereString ~= " AND " if $++ > 0;

            $whereString ~= "$col = ";

            given $match {
                when Int    { $whereString ~= "$match"; }
                default     { $whereString ~= "'$match'"; }
            }

            LAST { $whereString ~= ")"; }
        }

        $!dbs ~= qq:to/STATEMENT/;
        	WHERE $whereString
        STATEMENT
    }

    multi method where (@matches)
    {
        my $whereString = '';

        for @matches -> %matches {
            $whereString ~= " OR " if $++ > 0;

            for %matches.kv -> $col, $match {
                FIRST { $whereString ~= "("; }
                $whereString ~= " AND " if $++ > 0;

                $whereString ~= "$col = ";

                given $match {
                    when Int    { $whereString ~= "$match"; }
                    default     { $whereString ~= "'$match'"; }
                }

                LAST { $whereString ~= ")"; }
            }
        }

        $!dbs ~= qq:to/STATEMENT/;
        	WHERE $whereString
        STATEMENT
    }

    multi method where (*@matches)
    {
        for @matches -> @match {
            say @match;

        }
        exit;
    }

    method get ()
    {
        say $!dbs;
        exit;
        $!dbe = $!dbc.prepare($!dbs);
        $!dbe.execute();
    }

    method all ()
    {
        return $!dbe.allrows().Array;
    }

    method first ()
    {
        return $!dbe.row();
    }
}
