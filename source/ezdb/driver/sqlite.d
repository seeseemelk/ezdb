/**
A SQLite driver for EzDb.
*/
module ezdb.driver.sqlite;

import ezdb.repository;
import ezdb.entity;
import ezdb.foreign;

import d2sqlite3;
import optional;

import std.conv;
import std.stdio;
import std.range;
import std.algorithm;
import std.traits;
import std.exception;

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

private template GetIdColumn(Entity)
{
    enum GetIdColumn = getSymbolsByUDA!(Entity, primaryKey)[0].stringof;
}

/**
A factory that can create SQLite databases.
*/
final class SqliteFactory
{
    private Database _db;
    private int _openConnections = 0;
    private bool _open = true;

    /**
    Creates a new SQLite factory.
    */
    this(string filename = "sqlite.db")
    {
        _db = Database(filename);
        _db.execute("PRAGMA foreign_keys = ON;");
    }

    /**
    Returns `true` if the factory has been fully closed, `false` if it is still
    possible to open new repositories.
    */
    bool isClosed()
    {
        return !_open;
    }

    /**
    Opens a connection to a SQLite database.
    */
    auto open(Repository)()
    in (isClosed == false)
    {
        _openConnections++;
        return new SqliteDriver!Repository(this);
    }

    /**
    Attempts to close the database, if it is no longer being used.
    */
    private void close()
    {
        _openConnections--;
        if (_openConnections <= 0)
        {
            _open = false;
            _db.close();
        }
    }

    /**
    Gets a reference to the Sqlite database.
    */
    private ref Database db()
    {
        return _db;
    }
}

/**
Implements a repository using a Sqlite database.
*/
final class SqliteDriver(Db : Repository!Entity, Entity) : Db
{
    private enum Table = Entity.stringof;
    private enum IdColumn = GetIdColumn!Entity;
    private SqliteFactory _factory;
    private immutable DDLStrategy _strategy;

    /**
    Creates a SQLite database.
    Params:
      filename = The name of the file used to store the database.
    */
    this(SqliteFactory factory, DDLStrategy strategy = DDLStrategy.create)
    {
        _strategy = strategy;
        _factory = factory;

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
        _factory.db.run(text("DROP TABLE IF EXISTS ", Table));
    }

    private void createTable()
    {
        string statement = CreationStatement!Entity;
        _factory.db.run(statement);
    }

    private PrimaryKeyType!Entity lastRowId()
    {
        return _factory.db
            .execute("SELECT last_insert_rowid()")
            .oneValue!(PrimaryKeyType!Entity);
    }

    override void close()
    {
        _factory.close();
    }

    override void remove(PrimaryKeyType!Entity id)
    {
        auto statement = _factory.db.prepare(text("DELETE FROM ", Table, " WHERE ", IdColumn, " = :id"));
        statement.bind(":id", id);
        statement.execute();
        statement.reset();
    }

    override Optional!Entity find(PrimaryKeyType!Entity id)
    {
        auto statement = _factory.db.prepare(text("SELECT * FROM ", Table, " WHERE ",
            IdColumn, " = :id"));
        statement.bind(":id", id);
        auto results = statement.execute();
        if (results.empty)
            return no!Entity;
        auto result = results.front().as!Entity;
        statement.reset();
        return some(result);
    }

    override Entity[] findAll()
    {
        auto statement = _factory.db.prepare(text("SELECT * FROM ", Table));
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
        string statementString = InsertStatement!Entity;
        auto statement = _factory.db.prepare(statementString);
        static foreach (name; FieldNameTuple!Entity)
        {
            static if (!hasUDA!(__traits(getMember, Entity, name), primaryKey))
            {
                statement.bind(":" ~ name, __traits(getMember, entity, name));
            }
        }
        statement.execute();
        statement.reset();
        return find(lastRowId()).front;
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
    string[] foreignKeys;
    static foreach (memberName; FieldNameTuple!Entity)
    {{
        string[] attributes = [memberName];
        alias member = __traits(getMember, Entity, memberName);

        // Add the SQL type identifier
        static if (is(typeof(member) == int))
            attributes ~= "INTEGER";
        else static if (is(typeof(member) == string))
            attributes ~= "TEXT";
        else
            assert(0, "Cannot convert field of type " ~ typeof(member).stringof ~ " to a SQL type");

        // Add the primary key attribute if necessary.
        static if (hasUDA!(member, primaryKey))
            attributes ~= ["PRIMARY KEY", "AUTOINCREMENT"];
        else static if (IsForeign!(member))
        {
            alias foreign = GetForeignEntity!member;
            foreignKeys ~= text("FOREIGN KEY (", memberName, ") REFERENCES ",
                foreign.stringof, "(", GetIdColumn!foreign, ")");
        }

        // Add the Not Null attribute.
        attributes ~= "NOT NULL";
        lines ~= attributes.join(' ');
    }}
    return (lines ~ foreignKeys).join(", ");
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
    auto db = new SqliteFactory(":memory:").open!Repo;
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
    auto db = new SqliteFactory(":memory:").open!Repo;
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
    auto db = new SqliteFactory(":memory:").open!Repo;
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
    auto db = new SqliteFactory(":memory:").open!Repo;
    scope(exit) db.close();

    Entity toSave;
    toSave.value = 5;

    const saved = db.save(toSave);

    assert(db.findAll() == [saved], "Did not correctly retrieve all results");
}

@("remove() should remove an instance")
unittest
{
    static struct Entity
    {
        @primaryKey int id;
        int value;
    }
    static interface Repo : Repository!Entity {}
    auto db = new SqliteFactory(":memory:").open!Repo;
    scope(exit) db.close();

    Entity toSave;
    const saved = db.save(toSave);
    db.remove(saved.id);
}

@("find() should return an empty optional if no row can be found")
unittest
{
    static struct Entity
    {
        @primaryKey int id;
        int value;
    }
    static interface Repo : Repository!Entity {}
    auto db = new SqliteFactory(":memory:").open!Repo;
    scope(exit) db.close();

    assert(db.find(0).empty, "Result was not empty");
}

@("An invalid foreign key will cause an error")
unittest
{
    static struct Parent
    {
        @primaryKey int id;
    }

    static struct Child
    {
        @primaryKey
        int id;

        @foreign!Parent
        int child;
    }

    static interface ParentRepo : Repository!Parent {}
    static interface ChildRepo : Repository!Child {}
    auto factory = new SqliteFactory(":memory:");
    auto parentDb = factory.open!ParentRepo;
    scope(exit) parentDb.close();
    auto db = factory.open!ChildRepo;
    scope(exit) db.close();

    Child child;
    child.child = 5;
    assertThrown(db.save(child));
}

@("A valid foreign key will be accepted")
unittest
{
    static struct Parent
    {
        @primaryKey int id;
    }

    static struct Child
    {
        @primaryKey
        int id;

        @foreign!Parent
        int child;
    }

    static interface ParentRepo : Repository!Parent {}
    static interface ChildRepo : Repository!Child {}
    auto factory = new SqliteFactory(":memory:");
    auto parentDb = factory.open!ParentRepo;
    scope(exit) parentDb.close();
    auto db = factory.open!ChildRepo;
    scope(exit) db.close();

    Parent parent;
    parent = parentDb.save(parent);

    Child child;
    child.child = parent.id;
    db.save(child);
}
