CREATE CONSTRAINT users_unique_idx IF NOT EXISTS
FOR (u:User) REQUIRE u.id IS UNIQUE;

CREATE CONSTRAINT movies_unique_idx IF NOT EXISTS
FOR (m:Movie) REQUIRE m.id IS UNIQUE;

CREATE CONSTRAINT genre_unique__idx IF NOT EXISTS
FOR (g:Genre) REQUIRE g.name IS UNIQUE;


LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS userRow
CALL {
  WITH userRow
  MERGE (u:User {id: toInteger(userRow.userId)})
  SET
    u.gender = userRow.gender,
    u.age = toInteger(userRow.age),
    u.occupation = userRow.occupation
};

LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS movieRow
CALL {
  WITH movieRow

  MERGE (m:Movie {id: toInteger(movieRow.movieId)})
  SET m.title = movieRow.title

  WITH m, split(movieRow.genres, '|') AS genreList
  UNWIND genreList AS genreName

  MERGE (g:Genre {name: genreName})
  MERGE (m)-[:HAS_GENRE]->(g)
};

CALL apoc.periodic.iterate(
  "
  LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row
  RETURN row
  ",
  "
  MATCH (u:User {id: toInteger(row.userId)})
  MATCH (m:Movie {id: toInteger(row.movieId)})
  MERGE (u)-[r:RATED]->(m)
  SET r.rating = toInteger(row.rating),
      r.timestamp = toInteger(row.timestamp)
  ",
  {
    batchSize: 10000,
    parallel: false
  }
);


MATCH (u:User) RETURN count(u) AS users;
MATCH (m:Movie) RETURN count(m) AS movies;
MATCH (g:Genre) RETURN count(g) AS genres;
MATCH ()-[r:RATED]->() RETURN count(r) AS ratings;