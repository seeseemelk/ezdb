/**
Contains a completely in-memory database.
*/
module ezdb.driver.memory;

import ezdb.repository;
import ezdb.entity;

import optional;

import std.exception;

/**
An in-memory database, useful for unit-testing.
This memory does not need special cleanup.

Note that this database is not optimised for high performance, it should only
be used for small amounts of data.
*/
class MemoryDriver(Db : Repository!Entity, Entity) : Db
{
    private Entity[PrimaryKeyType!Entity] _entities;
    private PrimaryKeyType!Entity _nextId = 1;

    override void close()
    {
    }

    override Entity save(Entity entity)
    {
        setPrimaryKey(entity, _nextId);
        _entities[getPrimaryKey(entity)] = entity;
        _nextId++;
        return entity;
    }

    override Optional!Entity find(PrimaryKeyType!Entity id)
    {
        if (id !in _entities)
            return no!Entity;
        return some(_entities[id]);
    }

    override Entity[] findAll()
    {
        Entity[] entities;
        foreach (_, entity; _entities)
            entities ~= entity;
        return entities;
    }

    override void remove(PrimaryKeyType!Entity id)
    {
        _entities.remove(id);
    }
}

@("Can create a Memory database")
unittest
{
    static struct Entity
    {
        @primaryKey int id;
    }
    static interface Repo : Repository!Entity {}
    auto db = new MemoryDriver!Repo;
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
    auto db = new MemoryDriver!Repo;
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
    auto db = new MemoryDriver!Repo;
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
    auto db = new MemoryDriver!Repo;
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
    auto db = new MemoryDriver!Repo;
    scope(exit) db.close();

    Entity toSave;
    const saved = db.save(toSave);
    db.remove(saved.id);
}
