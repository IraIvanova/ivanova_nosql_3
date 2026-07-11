// PAGE RANK
// Крок 1: матеріалізуємо ребра фільм-фільм через спільних користувачів
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE size([(m1)<-[:RATED]-() | 1]) > 20
  AND size([(m2)<-[:RATED]-() | 1]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Крок 2: створюємо проєкцію на основі матеріалізованих ребер
CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: запуск алгоритма PageRank
CALL gds.pageRank.stream('movieGraph',  {
    relationshipWeightProperty: 'weight'
  })
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS name, score
ORDER BY score DESC
LIMIT 10;


// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;



// Louvain
// Крок 1: матеріалізуємо ребра користувач-користувач через спільні фільми
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating =5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// Крок 2: створюємо проєкцію
CALL gds.graph.project(
  'userSimilarity',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: запускаємо Louvain
CALL gds.louvain.write(
    'userSimilarity',
    {
        relationshipWeightProperty: 'weight',
        writeProperty: 'communityId'
    }
)
YIELD communityCount, modularity, modularities
RETURN communityCount, modularity, modularities;


// Крок 4: 10 найбільших кластерів
MATCH (u:User)
WHERE u.communityId IS NOT NULL
RETURN u.communityId, count(u) AS userCount
ORDER BY userCount DESC
LIMIT 10;


// Крок 5: Топ-3 жанри для кожної з 10 спільнот
MATCH (u:User)
WHERE u.communityId IS NOT NULL
WITH u.communityId AS communityId, count(u) AS communitySize
ORDER BY communitySize DESC
LIMIT 10

MATCH (user:User {communityId: communityId})-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE r.rating >= 4
WITH communityId, communitySize, g.name AS genre, count(*) AS ratings_count
ORDER BY communityId, ratings_count DESC

WITH communityId,
     communitySize,
     collect({genre: genre, ratings_count: ratings_count})[0..3] AS topGenres
RETURN communityId, communitySize, topGenres
ORDER BY communitySize DESC;


// Крок 6: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-() DELETE sim;



// Алгоритм Дейкстри
// Крок 1: Проєкція потрібна та сама, що і для Louvain — пересотворіть, якщо видалили
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

//Крок 2: Створюємо проекцію
CALL gds.graph.project(
  'userGraph',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: знаходження найкоротшого шлязу за допомогою алгоритма Dijkstra
MATCH (source:User {id: 18}),
      (target:User {id: 2125})
CALL gds.shortestPath.dijkstra.stream(
  'userGraph',
  {
    sourceNode: source,
    targetNode: target
  }
)
YIELD totalCost, nodeIds
RETURN
  totalCost,
  [nodeId IN nodeIds | gds.util.asNode(nodeId).id] AS userPath;

// Крок 4: видаляємо проєкцію
CALL gds.graph.drop('userGraph');