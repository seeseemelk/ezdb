[![Build Status](https://jenkins.ruska.space/buildStatus/icon?job=ezdb%2Fmaster)](https://jenkins.ruska.space/job/ezdb/job/master/)

# EzDb
EzDb is a database system similar to Spring Data JPA.
It currently supports both SQLite and an in-memory database.

## Usage
Here is a simple example that explains the usage of EzDb:

```d
import ezdb;

// Define the entity representing a single record in a table.
struct SomeEntity
{
	@primaryKey
	int id;

	string someValue;
}

// A repository that functions as the interface to a repository.
interface SomeRepository : Repository!SomeEntity
{
}

// Create an instance for the repository.
auto db = makeRepository!SomeRepository;
scope(exit) db.close();

// Create an entity and save it.
SomeEntity newEntity;
newEntity.someValue = "hello, world!";
SomeEntity savedEntity = db.save(newEntity);
```

## Unit-testing
A system requiring a database can easily be tested using the `mockRepository` function.
```d
import ezdb;

unittest
{
	auto db = mockRepository!SomeRepository;
	SomeEntity mockEntity;
	mockEntity.someValue = "hello, test!";
	db.save(mockEntity);
	// Do the rest of the test here
}
```

## Other functionality
All supported operations on a database can currently be found in the package `ezdb.repository`.
Check out the documentation!
