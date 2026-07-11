MATCH (m:Movie)-[:HAS_GENRE]->(:Genre {name: "Thriller"})
MATCH (u:User)-[r:RATED]->(m)
WITH m, avg(r.rating) AS avg_rating
WHERE avg_rating > 4
RETURN m.title, avg_rating
ORDER BY avg_rating DESC;


# Знайти користувачів, які поставили оцінку 5 більш ніж 50 фільмам:

MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH u, count(m) AS movies_count
WHERE movies_count > 50
RETURN u.id, movies_count
ORDER BY movies_count DESC;


# Знайти фільми, які обидва користувачі (наприклад, userId=1 і userId=2) оцінили високо (рейтинг ≥ 4):

MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating >= 4 AND u.id IN [1, 2]
WITH m, count(DISTINCT u) AS users_count
WHERE users_count = 2
RETURN m.title


# Знайти жанри, чиї фільми стабільно отримують високі оцінки — середній рейтинг і кількість оцінок:

MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre)
MATCH (u:User)-[r:RATED]->(m)
WITH g, avg(r.rating) AS avg_rating, count(r) AS ratings_count
WHERE avg_rating > 3.7 AND ratings_count >= 1000
RETURN g.name, avg_rating, ratings_count
ORDER BY avg_rating DESC;


# Рекомендація «користувачі зі схожими смаками також дивилися»:
# для заданого користувача знайти фільми, які він ще не дивився, але високо оцінили користувачі з подібними смаками:

MATCH (u:User {id: 5})-[r:RATED]->(m:Movie)
WHERE r.rating >= 4

MATCH (u2:User)-[r2:RATED]->(m)
WHERE u <> u2 AND r2.rating >= 4

MATCH (u2)-[r3:RATED]->(recommended:Movie)
WHERE r3.rating >= 4
  AND NOT EXISTS {
    MATCH (u)-[:RATED]->(recommended)
  }

WITH recommended,
     count(DISTINCT u2) AS similar,
     avg(r3.rating) AS avgRating
RETURN recommended.title,
       similar,
       avgRating
ORDER BY similar DESC, avgRating DESC
LIMIT 10;


# Знайти найкоротший ланцюжок зв’язку між двома користувачами через спільні фільми:

MATCH (u1:User {id: 1}), (u2:User {id: 2})
MATCH path = shortestPath((u1)-[:RATED*]-(u2))
RETURN path, length(path) AS pathLength;
