MATCH (:User)-[r:RATED]->(m:Movie)
WITH m, count(r) AS degree
WHERE degree > 2000
RETURN m.title, degree
ORDER BY degree DESC
LIMIT 20


// 1. Користувачі, які поставили найбільшу кількість оцінок
MATCH (u:User)-[r:RATED]->(:Movie)
RETURN u.id AS userId,
       count(r) AS degree
ORDER BY degree DESC
LIMIT 5;


// 2. Фільми з найбільшою кількістю оцінок
MATCH (:User)-[r:RATED]->(m:Movie)
RETURN m.id, m.title, count(r) AS degree
ORDER BY degree DESC
LIMIT 5;


// 3. Жанри з найбільшою кількістю фільмів
MATCH (m:Movie)-[rel:HAS_GENRE]->(g:Genre)
RETURN g.name, count(rel) AS degree
ORDER BY degree DESC
LIMIT 5;


// 4. Загальний пошук вузлів із найбільшою кількістю зв’язків
MATCH (n)
WITH n, count { (n)--() } AS degree
RETURN
    labels(n) AS labels,
    CASE WHEN n:User THEN n.id END AS userId,
    CASE WHEN n:Movie THEN n.id END AS movieId,
    CASE WHEN n:Movie THEN n.title
         WHEN n:Genre THEN n.name
    END AS name,
    degree
ORDER BY degree DESC
LIMIT 10;
