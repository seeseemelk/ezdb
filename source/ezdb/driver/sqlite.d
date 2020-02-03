/**
A SQLite driver for EzDb.
*/
module ezdb.driver.sqlite;

import ezdb.repository;
import ezdb.entity;

import d2sqlite3;

import std.conv;
import std.stdio;
import std.range;
import std.algorithm;
import std.traits;

/**
The strategy used to create tables.
*/
enum DDLStrategy
{
    /// Creates the table if one doesn't exist.
    /// Doesn't do anything else.
    create,

    /// Drops a table if one exists, and then recreates it.
    drop_create,
}

/**
Implements a repository using a Sqlite database.
*/
class SqliteDriver(Db : Repository!Entity, Entity) : Db
{
    private enum Table = Entity.stringof;
    private enum IdColumn = getSymbolsByUDA!(Entity, primaryKey)[0].stringof;
    private Database _db;
    private immutable DDLStrategy _strategy;

    /**
    Creates a SQLite database.
    Params:
      filename = The name of the file used to store the database.
    */
    this(string filename = "sqlite.db", DDLStrategy strategy = DDLStrategy.create)
    {
        _db = Database(filename);
        _strategy = strategy;

        final switch (strategy)
        {
            case DDLStrategy.drop_create:
                dropTable();
                createTable();
                break;
            case DDLStrategy.create:
                createTable();
        }
    }

    private void dropTable()
    {
        _db.run(text("DROP TABLE IF EXISTS ", Table));
    }

    private void createTable()
    {
        _db.run(CreationStatement!Entity);
    }

    private TypeOfPrimaryKey!Entity lastRowId()
    {
        return _db
            .execute("SELECT last_insert_rowid()")
            .oneValue!(TypeOfPrimaryKey!Entity);
    }

    override void close()
    {
        _db.close();
    }

    override void remove(TypeOfPrimaryKey!Entity id)
    {
        assert(0, "Not implemented");
    }

    override Entity find(TypeOfPrimaryKey!Entity id)
    {
        auto statement = _db.prepare(text("SELECT * FROM ", Table, " WHERE ",
            IdColumn, " = :id"));
        statement.bind(":id", id);
        auto results = statement.execute();
        auto result = results.front().as!Entity;
        statement.reset();
        return result;
    }

    override Entity[] findAll()
    {
        auto statement = _db.prepare(text("SELECT * FROM ", Table));
        auto results = statement.execute();
        Entity[] entities;
        foreach (result; results)
        {
            entities ~= result.as!Entity;
        }
        statement.reset();
        return entities;
    }

    override Entity save(Entity entity)
    {
        auto statement = _db.prepare(InsertStatement!Entity);
        static foreach (name; FieldNameTuple!Entity)
        {
            static if (!hasUDA!(__traits(getMember, Entity, name), primaryKey))
            {
                statement.bind(":" ~ name, __traits(getMember, entity, name));
            }
        }
        statement.execute();
        statement.reset();
        return find(lastRowId());
    }
}

private template CreationStatement(Entity)
{
    static CreationStatement = text("CREATE TABLE IF NOT EXISTS ", Entity.stringof,
        " (", parseCreationMembers!Entity, ")");
}

private string parseCreationMembers(Entity)()
{
    string[] lines;
    foreach (memberName; FieldNameTuple!Entity)
    {
        string[] attributes = [memberName];
        alias member = __traits(getMember, Entity, memberName);

        // Add the SQL type identifier
        if (is(typeof(member) == int))
            attributes ~= "INTEGER";
        else if (is(typeof(member) == string))
            attributes ~= "TEXT";
        else
            assert(0, "Cannot convert field of type " ~ typeof(member).stringof ~ " to a SQL type");

        // Add the primary key attribute if necessary.
        if (hasUDA!(member, primaryKey))
        {
            attributes ~= ["PRIMARY KEY", "AUTOINCREMENT"];
        }

        // Add the Not Null attribute.
        attributes ~= "NOT NULL";
        lines ~= attributes.join(' ');
    }
    return lines.join(", ");
}

private template InsertStatement(Entity)
{
    static InsertStatement = text("INSERT INTO ", Entity.stringof,
        "(", [FieldNameTuple!Entity].join(", "), ") VALUES ",
        "(", [FieldNameTuple!Entity].map!(member => ":" ~ member).join(", "), ")");
}

@("Can create a SQLite database")
unittest
{
    static struct Entity
    {
        @primaryKey int id;
    }
    static interface Repo : Repository!Entity {}
    auto db = new SqliteDriver!Repo(":memory:");
    scope(exit) db.close();
    assert(db !is null);
}

@("Empty database should return no results")
unittest
{
    static struct Entity
    {
        @primaryKey int id;
    }
    static interface Repo : Repository!Entity {}
    auto db = new SqliteDriver!Repo(":memory:");
    scope(exit) db.close();
    assert(db.findAll() == [], "findAll() should return an empty list of the database is empty");
}

@("Save() should return a saved instance")
unittest
{
    static struct Entity
    {
        @primaryKey int id;
        int value;
    }
    static interface Repo : Repository!Entity {}
    auto db = new SqliteDriver!Repo(":memory:");
    scope(exit) db.close();

    Entity toSave;
    toSave.value = 5;

    const saved1 = db.save(toSave);
    assert(saved1.value == 5, "Entity.value was not correctly saved");
    assert(saved1.id == 1, "Entity.id was not generated");

    const saved2 = db.save(toSave);
    assert(saved2.value == 5, "Entity.value was not correctly saved");
    assert(saved2.id == 2, "Entity.id was not generated");
}

@("findAll() should return all instances when saved")
unittest
{
    static struct Entity
    {
        @primaryKey int id;
        int value;
    }
    static interface Repo : Repository!Entity {}
    auto db = new SqliteDriver!Repo(":memory:");
    scope(exit) db.close();

    Entity toSave;
    toSave.value = 5;

    const saved = db.save(toSave);

    assert(db.findAll() == [saved], "Did not correctly retrieve all results");
}
