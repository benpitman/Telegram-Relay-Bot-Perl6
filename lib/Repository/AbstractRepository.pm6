#!/usr/bin/perl6

use v6;
use DBIish;

need Service::Service;
need Entity::Entity;

role AbstractRepository
{
    has $.table is rw;
    has $!dbc;
    has Str $!dbs;
    has $!dbe;
    has $!entity = Entity.new;
    has Str $!whereString;

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
        $!dbs.finish();
        $!dbc.dispose();
    }

    multi method insert (@rows where { @rows.first.WHAT === any(Pair, Hash) })
    {
        my Array @ids;
        my Array @id;

        for @rows -> %row {
            @id = self.insert(%row);

            last if $!entity.hasErrors();
            @ids.push: @id[0];
        }

        return @ids;
    }

    multi method insert (%row)
    {
        my Array @cols;
        my Array @vals;

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

        my Str $colString = @cols.join(', ');
        my Str $valString = @vals.join(', ');

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

    multi method insert (@columns, @values where { @columns.elems === @values.elems })
    {
        my %row = @columns Z=> @values;
        return self.insert(%row);
    }

    multi method select (*@cols where { $_.all ~~ Str })
    {
        my Str $colString = @cols.join(', ');

        $!dbs = qq:to/STATEMENT/;
        	SELECT $colString
        	FROM $!table
        STATEMENT
    }

    multi method select (@cols)
    {
        self.select(|@cols);
    }

    multi method where (@whereCols, @operators, @matches where { @whereCols.elems === @matches.elems })
    {
        my Int $index = 0;
        my Str $operator;
        $!whereString ~= '(';

        for @whereCols Z @matches -> [$col, $match] {
            $!whereString ~= " AND " if $index = $++;

            $operator = @operators[$index] // '=';
            $!whereString ~= "$col $operator ";

            given $match {
                when Int    { $!whereString ~= "$match"; }
                default     { $!whereString ~= "'$match'"; }
            }
        }
        $!whereString ~= ')';
    }

    multi method where (%matches)
    {
        my @keys = %matches.keys;
        my @vals = %matches.values;
        self.where(@keys, [], @vals);
    }

    multi method where (@matches where { @matches.first.WHAT === any(Pair, Hash) })
    {
        for @matches -> %matches {
            $!whereString ~= " OR " if $++;
            self.where(%matches);
        }
    }

    multi method where (@whereCols, @matches where { @whereCols.elems === @matches.elems })
    {
        self.where(@whereCols, [], @matches);
    }

    multi method where ($whereCol, $operator, $match)
    {
        self.where([$whereCol], [$operator], [$match]);
    }

    multi method where ($whereCol, $match)
    {
        self.where([$whereCol], [], [$match]);
    }

    multi method orWhere (|sig)
    {
        $!whereString ~= ' OR ';
        self.where(|sig);
    }

    method get ()
    {
        $!dbs ~= qq:to/STATEMENT/ if ?$!whereString;
        WHERE $!whereString
        STATEMENT

        say $!dbs;
        exit;

        try {
            $!dbe = $!dbc.prepare($!dbs);
            $!dbe.execute();

            CATCH {
                $!entity.addError("$_");
                return;
            }
        }
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
