/*==============================================================
  CineChef - Fase 3d: películas, tanda 1 de 4
  25 películas reales con sinopsis originales y géneros por nombre.
  Años y duraciones en minutos; el script es repetible.
==============================================================*/
USE CineChefDB;
GO

INSERT INTO dbo.Movies (Title, ReleaseYear, RuntimeMin, MinAge, Synopsis)
SELECT source.Title, source.ReleaseYear, source.RuntimeMin, source.MinAge, source.Synopsis
FROM (VALUES
(N'12 Angry Men',1957,96,12,N'A tense jury-room drama built from heat, silence, and moral pressure. The film feels claustrophobic yet intensely human as certainty gives way to doubt, patience, and reluctant empathy. Its modest setting becomes a charged arena where every pause carries weight.'),
(N'Tokyo Story',1953,136,12,N'Quiet and deeply melancholic, this family drama observes distance growing between parents and their adult children. Its measured rhythm, gentle rooms, and compassionate faces create a bittersweet atmosphere where ordinary routines reveal love, disappointment, and the ache of time passing.'),
(N'Bicycle Thieves',1948,89,7,N'Rome appears both open and unforgiving in this spare, aching story of a father and son moving through crowded streets. The mood is tender, restless, and quietly devastating, finding dignity in small gestures while poverty turns an ordinary day into a moral journey.'),
(N'Singin'' in the Rain',1952,103,0,N'Brilliantly cheerful and irresistibly buoyant, this musical turns Hollywood uncertainty into color, rhythm, and physical comedy. Rain becomes a playground, romance feels mischievous, and every dance carries the warmth of performers determined to make joy survive behind the scenes.'),
(N'The Apartment',1960,125,12,N'Funny, romantic, and touched by loneliness, this city comedy glows with office lights and late-night walks. Its characters stumble through compromises while searching for kindness, giving the film a wistful warmth that gradually turns cynicism into tenderness and hope.'),
(N'Psycho',1960,109,18,N'Cold, unsettling, and expertly controlled, this thriller begins with ordinary unease before turning familiar spaces into traps. Shadows, silence, and sharp musical shocks create a nightmare atmosphere where identity feels unstable and safety can vanish in a single glance.'),
(N'Rear Window',1954,112,12,N'Sunlit apartments become a seductive maze of suspicion in this elegant, suspenseful mystery. The pleasure is voyeuristic but uneasy, balancing romantic frustration with mounting danger. Its bright courtyards and confined viewpoint make curiosity feel both exhilarating and increasingly perilous.'),
(N'Spirited Away',2001,125,7,N'Enchanting and dreamlike, this animated journey moves through a bathhouse world filled with strange spirits, tenderness, and quiet danger. Its atmosphere shifts from fear to wonder without losing emotional warmth, making transformation feel mysterious, beautiful, and earned through courage.'),
(N'Toy Story',1995,81,0,N'Playful, warm, and gently nostalgic, this animated adventure imagines the secret life of treasured toys. Comedy and friendship keep the pace bright, while the emotional core understands childhood change. It feels like opening an old toy chest and finding a whole world still alive.'),
(N'The Lion King',1994,88,0,N'Grand landscapes, memorable music, and a tender coming-of-age spirit give this animated story its enduring glow. It moves between exuberant humor and genuine grief, creating a family adventure about belonging, responsibility, and returning home with a wiser heart.'),
(N'My Neighbor Totoro',1988,86,0,N'Soft, patient, and full of rural wonder, this animated film sees childhood through tall grass, rain, old trees, and mysterious creatures. Its gentle atmosphere makes everyday life feel enchanted while offering quiet reassurance about family, imagination, and waiting through uncertain days.'),
(N'The Princess Bride',1987,98,7,N'Whimsical, romantic, and knowingly adventurous, this fairy tale balances swordplay with deadpan jokes and sincere affection. Its storybook atmosphere feels comforting rather than childish, inviting viewers into a world where loyalty, cleverness, and true love can still defeat absurd odds.'),
(N'Back to the Future',1985,116,7,N'Fast, funny, and irresistibly energetic, this time-travel adventure mixes suburban familiarity with bright science-fiction invention. Its atmosphere is playful but emotionally grounded, turning history into a comic puzzle about family, identity, and the surprising courage to shape one''s future.'),
(N'Alien',1979,117,18,N'Dark industrial corridors and near-total isolation make this science-fiction horror feel airless and immediate. The ship becomes a haunted workplace where routine collapses into survival, combining patient dread, stark design, and a fierce atmosphere of human vulnerability against the unknown.'),
(N'The Godfather',1972,175,18,N'Operatic, autumnal, and morally shadowed, this crime drama surrounds power with family rituals, lavish rooms, and quiet menace. Its atmosphere is seductive before it becomes tragic, tracing how loyalty and ambition can transform intimacy into obligation and violence.'),
(N'Casablanca',1942,102,12,N'Romantic and wistful beneath its wartime tension, this classic fills smoky rooms with music, memory, and difficult choices. The city feels suspended between escape and sacrifice, while restrained performances give lost love a noble, aching glow that never becomes sentimental.'),
(N'Seven Samurai',1954,207,12,N'Epic in scale but intimate in feeling, this Japanese adventure moves from quiet village anxiety to muddy, exhilarating battle. Its atmosphere is communal, humorous, and tragic at once, honoring courage while remembering the cost paid by ordinary people and restless warriors alike.'),
(N'Amelie',2001,122,7,N'Playful, romantic, and gently surreal, this Parisian film turns small acts of kindness into colorful emotional adventures. Its warm visual style and curious narration make loneliness feel inviting rather than bleak, as imagination helps guarded people rediscover connection and delight.'),
(N'Parasite',2019,132,16,N'Sharp, darkly funny, and increasingly unnerving, this social thriller moves between cramped rooms and polished luxury. Its mood shifts with elegant precision from playful opportunity to tightening menace, exposing how class, architecture, and resentment can turn hospitality into a trap.'),
(N'The Lives of Others',2006,137,12,N'Cold surveillance rooms gradually give way to moral awakening in this restrained German drama. The atmosphere is tense and gray but never without compassion, showing how art, privacy, and a small act of mercy can reopen a conscience damaged by obedience.'),
(N'Cinema Paradiso',1988,155,7,N'Warmly nostalgic and touched by sadness, this Italian drama remembers a village cinema as a place of friendship, escape, and first dreams. Its atmosphere glows with projected light and old music, while adulthood looks back at the people and moments that made a life possible.'),
(N'The Shawshank Redemption',1994,142,16,N'Patient, humane, and quietly hopeful, this prison drama finds light in friendship, storytelling, and persistence. The setting is harsh, yet the emotional atmosphere keeps expanding, suggesting that dignity can survive confinement and that hope is strongest when shared over many years.'),
(N'Mad Max: Fury Road',2015,120,16,N'Furious, dusty, and visually overwhelming, this action film turns a wasteland chase into a fierce movement toward freedom. Its momentum rarely slackens, but beneath the spectacle lies a surprisingly hopeful mood about solidarity, survival, and refusing to serve a tyrant.'),
(N'Moonlight',2016,111,16,N'Intimate and quietly luminous, this coming-of-age drama follows identity through three stages of one life. Blue night, ocean water, and spare conversations create a tender atmosphere where vulnerability feels dangerous yet beautiful, and small moments of recognition become acts of rescue.'),
(N'Get Out',2017,104,16,N'Satirical, tense, and increasingly nightmarish, this horror film begins with social awkwardness before turning politeness into a weapon. Its bright domestic spaces feel wrong in subtle ways, building dread through controlled discomfort while keeping a sharp eye on race and power.')
) AS source (Title, ReleaseYear, RuntimeMin, MinAge, Synopsis)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Movies AS target
    WHERE target.Title = source.Title AND target.ReleaseYear = source.ReleaseYear
);
GO

INSERT INTO dbo.MovieGenres (MovieId, GenreId)
SELECT movie.MovieId, genre.GenreId
FROM (VALUES
(N'12 Angry Men',1957,N'Drama'),(N'12 Angry Men',1957,N'Mystery'),
(N'Tokyo Story',1953,N'Drama'),
(N'Bicycle Thieves',1948,N'Drama'),
(N'Singin'' in the Rain',1952,N'Comedy'),(N'Singin'' in the Rain',1952,N'Musical'),(N'Singin'' in the Rain',1952,N'Romance'),
(N'The Apartment',1960,N'Comedy'),(N'The Apartment',1960,N'Drama'),(N'The Apartment',1960,N'Romance'),
(N'Psycho',1960,N'Horror'),(N'Psycho',1960,N'Thriller'),(N'Psycho',1960,N'Mystery'),
(N'Rear Window',1954,N'Thriller'),(N'Rear Window',1954,N'Mystery'),
(N'Spirited Away',2001,N'Animation'),(N'Spirited Away',2001,N'Fantasy'),(N'Spirited Away',2001,N'Family'),
(N'Toy Story',1995,N'Animation'),(N'Toy Story',1995,N'Comedy'),(N'Toy Story',1995,N'Family'),
(N'The Lion King',1994,N'Animation'),(N'The Lion King',1994,N'Family'),(N'The Lion King',1994,N'Drama'),
(N'My Neighbor Totoro',1988,N'Animation'),(N'My Neighbor Totoro',1988,N'Family'),(N'My Neighbor Totoro',1988,N'Fantasy'),
(N'The Princess Bride',1987,N'Adventure'),(N'The Princess Bride',1987,N'Fantasy'),(N'The Princess Bride',1987,N'Romance'),
(N'Back to the Future',1985,N'Adventure'),(N'Back to the Future',1985,N'Comedy'),(N'Back to the Future',1985,N'Sci-Fi'),
(N'Alien',1979,N'Sci-Fi'),(N'Alien',1979,N'Horror'),(N'Alien',1979,N'Thriller'),
(N'The Godfather',1972,N'Crime'),(N'The Godfather',1972,N'Drama'),
(N'Casablanca',1942,N'Drama'),(N'Casablanca',1942,N'Romance'),(N'Casablanca',1942,N'War'),
(N'Seven Samurai',1954,N'Action'),(N'Seven Samurai',1954,N'Adventure'),(N'Seven Samurai',1954,N'Drama'),
(N'Amelie',2001,N'Comedy'),(N'Amelie',2001,N'Romance'),
(N'Parasite',2019,N'Thriller'),(N'Parasite',2019,N'Drama'),(N'Parasite',2019,N'Comedy'),
(N'The Lives of Others',2006,N'Drama'),(N'The Lives of Others',2006,N'Thriller'),
(N'Cinema Paradiso',1988,N'Drama'),(N'Cinema Paradiso',1988,N'Romance'),
(N'The Shawshank Redemption',1994,N'Drama'),
(N'Mad Max: Fury Road',2015,N'Action'),(N'Mad Max: Fury Road',2015,N'Adventure'),(N'Mad Max: Fury Road',2015,N'Sci-Fi'),
(N'Moonlight',2016,N'Drama'),(N'Moonlight',2016,N'Romance'),
(N'Get Out',2017,N'Horror'),(N'Get Out',2017,N'Thriller'),(N'Get Out',2017,N'Mystery')
) AS source (Title, ReleaseYear, GenreName)
JOIN dbo.Movies AS movie ON movie.Title = source.Title AND movie.ReleaseYear = source.ReleaseYear
JOIN dbo.Genres AS genre ON genre.Name = source.GenreName
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.MovieGenres AS target
    WHERE target.MovieId = movie.MovieId AND target.GenreId = genre.GenreId
);
GO

SELECT N'Movies' AS Catalog, COUNT(*) AS ItemCount,
       MIN(LEN(Synopsis)) AS MinSynopsisLength,
       MAX(LEN(Synopsis)) AS MaxSynopsisLength
FROM dbo.Movies
WHERE ReleaseYear IN (1942,1948,1952,1953,1954,1957,1960,1972,1979,1985,1987,1988,1994,1995,2001,2006,2015,2016,2017,2019);
SELECT N'MovieGenres' AS Catalog, COUNT(*) AS ItemCount
FROM dbo.MovieGenres AS mg
JOIN dbo.Movies AS movie ON movie.MovieId = mg.MovieId
WHERE movie.ReleaseYear IN (1942,1948,1952,1953,1954,1957,1960,1972,1979,1985,1987,1988,1994,1995,2001,2006,2015,2016,2017,2019);
GO
