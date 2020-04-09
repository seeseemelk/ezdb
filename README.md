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

## Foreign keys
Foreign keys are now also supported.
Support for foreign keys is purposefully limited as to avoid issues such as
eager/lazy loading, partial data, and cascading.
Use them with the following syntax:

```d
import ezdb;

struct Author
{
	@primaryKey
	int id;

	string name;
}

struct Book
{
	@primaryKey
	int id;

	string name;

	// Refer to the ID of the author of this book.
	@foreign!Author
	int author;
}

// Create the repositories
interface AuthorRepository : Repository!Author {}
interface BookRepository : Repository!Book {}

// Open the repositories
auto authorDb = makeRepository!AuthorRepository;
auto bookDb = makeRepository!BookRepository;

// Add an author
Author stevenKing;
stevenKing.name = "Steven King";
stevenKing = authorDb.save(stevenKing);

// Add a book
Book theShining;
theShining.name = "The Shining";
theShining.author = stevenKing.id;
theShining = bookDb.save(theShining);
```

## User-Defined Methods / Custom Queries
It is easy to add a custom query to a repository.
This is done in nearly the same way as Hibernate does.

Simply add a method to a repository, like this:
```
interface AuthorRepository : Repository!Book
{
	Book[] findByName(string name);
	Book[] findByAuthor(int authorId);
}
```

The following query types are supported:
|=|=|
| `find`/`select` | Searches for data, retrieving all data that was found. |

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
