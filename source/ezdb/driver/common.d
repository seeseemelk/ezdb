/**
Contains functionality common to all drivers.
*/
module ezdb.driver.common;

import ezdb.driver.sqlite;
import ezdb.driver.memory;
import ezdb.repository;

/**
Returns an instance for a repository.
*/
Db instance(Db : Repository!Entity, Entity)()
{
    return new SqliteDriver!Db;
}

/**
Returns an instance of a repository usable for unit testing.
*/
Db mock(Db : Repository!Entity, Entity)()
{
    return new MemoryDriver!Db;
}

unittest
{
    import ezdb.entity : primaryKey;

    static struct MyEntity
    {
        @primaryKey int id;

        string name;
    }

    static interface MyDatabase : Repository!MyEntity {}

    auto db = instance!MyDatabase;
    scope(exit) db.close();
    assert(db !is null);
}
