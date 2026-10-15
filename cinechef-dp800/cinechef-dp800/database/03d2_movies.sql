/*==============================================================
  CineChef - Fase 3d: películas, tanda 2 de 4
  25 películas nuevas; no modifica la tanda 1.
  Sinopsis originales y relaciones por título, año y género.
==============================================================*/
USE CineChefDB;
GO

INSERT INTO dbo.Movies (Title, ReleaseYear, RuntimeMin, MinAge, Synopsis)
SELECT source.Title, source.ReleaseYear, source.RuntimeMin, source.MinAge, source.Synopsis
FROM (VALUES
(N'Metropolis',1927,153,12,N'Grand, shadowy, and visually monumental, this silent science-fiction classic imagines a city divided by wealth and machinery. Its atmosphere is anxious yet dreamlike, filling towering spaces with workers, spectacle, and a persistent longing for human connection.'),
(N'Modern Times',1936,87,7,N'Playful physical comedy meets industrial unease as machines dictate the rhythm of everyday life. Beneath the gags, the film feels tender and humane, finding warmth in companionship and small acts of resilience when modern progress becomes absurdly overwhelming.'),
(N'Citizen Kane',1941,119,12,N'Mysterious, ambitious, and emotionally cool, this drama assembles a life through conflicting memories and grand interiors. Its atmosphere is both glamorous and lonely, suggesting that power, wealth, and public legend cannot easily recover the private tenderness that was lost.'),
(N'The 400 Blows',1959,99,12,N'Restless, wistful, and full of youthful uncertainty, this French coming-of-age film follows a boy moving through streets, classrooms, and adult misunderstandings. Its loose energy gradually turns melancholy, capturing the fragile freedom and loneliness of a childhood without a safe landing place.'),
(N'Persona',1966,83,16,N'Quietly disturbing and psychologically intimate, this Swedish drama dissolves the boundary between two women sharing an isolated house. Stark faces, sea air, and long silences create an atmosphere of identity slipping out of focus, beautiful and unsettling in equal measure.'),
(N'2001: A Space Odyssey',1968,149,12,N'Vast, patient, and hypnotic, this space epic treats the unknown with awe rather than simple explanation. Music, silence, and monumental images create a contemplative atmosphere where technology feels beautiful and frightening, while human purpose seems small beside cosmic time.'),
(N'Jaws',1975,124,12,N'Summer sunlight and cheerful beaches become charged with invisible danger in this landmark thriller. Its atmosphere builds through suggestion, waiting, and sudden violence, turning ordinary water into a place of dread while contrasting civic duty with fear, commerce, and denial.'),
(N'Rocky',1976,120,12,N'Gritty, romantic, and quietly hopeful, this Philadelphia drama finds dignity in routine, affection, and the decision to keep going. Its working-class streets feel worn but alive, while the training rhythm transforms a modest dream into an emotionally generous story about self-respect.'),
(N'The Shining',1980,146,18,N'Cold corridors, geometric rooms, and endless snow create a beautiful prison in this psychological horror film. The atmosphere moves from isolation to menace with chilling patience, making family space feel unreliable and turning creative ambition into a nightmare of repetition and violence.'),
(N'E.T. the Extra-Terrestrial',1982,115,7,N'Gentle wonder and suburban night-time magic shape this tender family adventure. Bicycles, forests, bedrooms, and glowing skies make childhood feel expansive, while friendship carries a soft sadness beneath the humor. It is hopeful, emotional, and deeply nostalgic without becoming cynical.'),
(N'Brazil',1985,132,16,N'Dizzy, darkly comic, and richly imaginative, this dystopian satire fills bureaucratic life with absurd machines and oppressive paperwork. Its visual extravagance hides a bleak emotional core, creating a world where fantasy becomes both refuge and dangerous resistance against official control.'),
(N'Grave of the Fireflies',1988,89,12,N'Tenderly animated but devastating in mood, this wartime story observes two siblings trying to preserve affection amid hunger and loss. Its quiet beauty makes the surrounding destruction feel even sharper, leaving an atmosphere of innocence, grief, and love that lingers long after the final image.'),
(N'Beauty and the Beast',1991,84,0,N'Romantic, musical, and warmly gothic, this animated fairy tale balances candlelit mystery with bright village comedy. Its atmosphere feels both grand and comforting, using song, enchanted objects, and genuine tenderness to imagine kindness as a force stronger than appearance or fear.'),
(N'Schindler''s List',1993,195,16,N'Somber, compassionate, and morally searching, this historical drama uses stark black-and-white imagery to face cruelty without turning suffering into spectacle. Its atmosphere is oppressive yet punctured by courage, showing how individual choices can carry fragile meaning inside a machinery of terror.'),
(N'Before Sunrise',1995,101,12,N'Romantic and conversational, this nocturnal film lets a city become an intimate playground for two strangers. Its atmosphere is light but temporary, full of walking, curiosity, and the melancholy knowledge that a perfect night may be valuable precisely because it cannot last.'),
(N'Princess Mononoke',1997,133,12,N'Fierce, mythic, and visually lush, this animated epic places forests, spirits, and industry in uneasy conflict. Its atmosphere refuses simple heroes or villains, creating a powerful sense of beauty under threat while compassion becomes the only path through competing forms of survival.'),
(N'The Matrix',1999,136,16,N'Cool, kinetic, and philosophically charged, this science-fiction thriller turns familiar city life into a polished illusion. Its atmosphere shifts from paranoid confusion to exhilarating liberation, blending martial arts, digital style, and a persistent question about what it means to choose reality.'),
(N'Crouching Tiger, Hidden Dragon',2000,120,12,N'Elegant swordplay and restrained longing move through misty forests, rooftops, and quiet courtyards. This wuxia romance feels graceful but emotionally stormy, balancing freedom against duty and giving every flight through the air the weight of an impossible desire.'),
(N'Pan''s Labyrinth',2006,118,16,N'Dark fairy-tale imagery collides with the harshness of postwar Spain in this haunting fantasy. Its atmosphere is beautiful, frightening, and mournful, using imagination not as simple escape but as a language for courage, disobedience, and the protection of innocence.'),
(N'No Country for Old Men',2007,122,16,N'Dry landscapes and near-silence make this crime thriller feel fated and unnerving. Violence arrives with startling calm, while weary faces suggest a world losing its familiar rules. The atmosphere is spare, morally unsettled, and haunted by the limits of wisdom.'),
(N'WALL-E',2008,98,0,N'Quietly charming and visually inventive, this animated film begins in loneliness among mountains of abandoned objects. Its gentle robot romance grows into a bright ecological adventure, balancing melancholy, comedy, and hope while finding wonder in attention, care, and a single small gesture.'),
(N'Inception',2010,148,12,N'Sleek, tense, and dreamlike, this science-fiction thriller folds cities and memories into elegant layers of uncertainty. Its atmosphere is thrilling but emotionally grounded by grief, making every impossible corridor and collapsing landscape feel like part of a difficult journey toward release.'),
(N'The Social Network',2010,120,12,N'Fast dialogue, cold interiors, and restless ambition give this drama a sharp, modern chill. The atmosphere is energized by invention but shadowed by isolation, presenting friendship and betrayal as competing currencies in a world where connection can be measured, copied, and owned.'),
(N'Roma',2018,135,16,N'Quietly luminous and deeply observant, this Mexican drama turns domestic routines into a landscape of memory. Black-and-white images, street sounds, and patient movement create a tender atmosphere where private labor, social change, and family love coexist with unspoken pain.'),
(N'Everything Everywhere All at Once',2022,139,16,N'Chaotic, funny, tender, and unexpectedly profound, this science-fiction comedy moves through a storm of possible lives. Its frantic energy gradually opens into compassion, suggesting that amid infinite choices, ordinary attention and family acceptance can become heroic acts.')
) AS source (Title,ReleaseYear,RuntimeMin,MinAge,Synopsis)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Movies AS target WHERE target.Title=source.Title AND target.ReleaseYear=source.ReleaseYear);
GO

INSERT INTO dbo.MovieGenres (MovieId,GenreId)
SELECT movie.MovieId,genre.GenreId
FROM (VALUES
(N'Metropolis',1927,N'Sci-Fi'),(N'Metropolis',1927,N'Drama'),
(N'Modern Times',1936,N'Comedy'),(N'Modern Times',1936,N'Drama'),
(N'Citizen Kane',1941,N'Drama'),(N'Citizen Kane',1941,N'Mystery'),
(N'The 400 Blows',1959,N'Drama'),
(N'Persona',1966,N'Drama'),(N'Persona',1966,N'Thriller'),
(N'2001: A Space Odyssey',1968,N'Sci-Fi'),(N'2001: A Space Odyssey',1968,N'Mystery'),
(N'Jaws',1975,N'Thriller'),(N'Jaws',1975,N'Horror'),
(N'Rocky',1976,N'Drama'),
(N'The Shining',1980,N'Horror'),(N'The Shining',1980,N'Thriller'),
(N'E.T. the Extra-Terrestrial',1982,N'Family'),(N'E.T. the Extra-Terrestrial',1982,N'Sci-Fi'),(N'E.T. the Extra-Terrestrial',1982,N'Adventure'),
(N'Brazil',1985,N'Sci-Fi'),(N'Brazil',1985,N'Comedy'),(N'Brazil',1985,N'Drama'),
(N'Grave of the Fireflies',1988,N'Animation'),(N'Grave of the Fireflies',1988,N'Drama'),(N'Grave of the Fireflies',1988,N'War'),
(N'Beauty and the Beast',1991,N'Animation'),(N'Beauty and the Beast',1991,N'Family'),(N'Beauty and the Beast',1991,N'Fantasy'),
(N'Schindler''s List',1993,N'Drama'),(N'Schindler''s List',1993,N'War'),(N'Schindler''s List',1993,N'Biography'),
(N'Before Sunrise',1995,N'Romance'),(N'Before Sunrise',1995,N'Drama'),
(N'Princess Mononoke',1997,N'Animation'),(N'Princess Mononoke',1997,N'Fantasy'),(N'Princess Mononoke',1997,N'Adventure'),
(N'The Matrix',1999,N'Sci-Fi'),(N'The Matrix',1999,N'Action'),(N'The Matrix',1999,N'Thriller'),
(N'Crouching Tiger, Hidden Dragon',2000,N'Action'),(N'Crouching Tiger, Hidden Dragon',2000,N'Adventure'),(N'Crouching Tiger, Hidden Dragon',2000,N'Romance'),
(N'Pan''s Labyrinth',2006,N'Fantasy'),(N'Pan''s Labyrinth',2006,N'Drama'),(N'Pan''s Labyrinth',2006,N'War'),
(N'No Country for Old Men',2007,N'Crime'),(N'No Country for Old Men',2007,N'Thriller'),
(N'WALL-E',2008,N'Animation'),(N'WALL-E',2008,N'Family'),(N'WALL-E',2008,N'Sci-Fi'),
(N'Inception',2010,N'Sci-Fi'),(N'Inception',2010,N'Thriller'),(N'Inception',2010,N'Action'),
(N'The Social Network',2010,N'Drama'),(N'The Social Network',2010,N'Biography'),
(N'Roma',2018,N'Drama'),
(N'Everything Everywhere All at Once',2022,N'Sci-Fi'),(N'Everything Everywhere All at Once',2022,N'Action'),(N'Everything Everywhere All at Once',2022,N'Comedy')
) AS source (Title,ReleaseYear,GenreName)
JOIN dbo.Movies AS movie ON movie.Title=source.Title AND movie.ReleaseYear=source.ReleaseYear
JOIN dbo.Genres AS genre ON genre.Name=source.GenreName
WHERE NOT EXISTS (SELECT 1 FROM dbo.MovieGenres AS target WHERE target.MovieId=movie.MovieId AND target.GenreId=genre.GenreId);
GO
