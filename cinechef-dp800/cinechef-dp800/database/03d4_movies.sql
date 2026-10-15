/*==============================================================
  CineChef - Fase 3d: películas, tanda 4 de 4
  25 películas nuevas; tanda final sin modificar las anteriores.
  Sinopsis originales y relaciones por título, año y género.
==============================================================*/
USE CineChefDB;
GO

INSERT INTO dbo.Movies (Title, ReleaseYear, RuntimeMin, MinAge, Synopsis)
SELECT source.Title, source.ReleaseYear, source.RuntimeMin, source.MinAge, source.Synopsis
FROM (VALUES
(N'The General',1926,78,7,N'Fast, inventive, and wonderfully physical, this silent comedy turns a train chase into a ballet of timing and stubborn courage. Its atmosphere is playful but genuinely suspenseful, celebrating ingenuity, loyalty, and the comic dignity of an ordinary man facing impossible complications.'),
(N'City Lights',1931,87,0,N'Tender, funny, and quietly heartbreaking, this silent romance moves through a city of accidents, generosity, and mistaken impressions. Its atmosphere balances graceful physical comedy with deep compassion, allowing a small act of love to become both a source of hope and a painful secret.'),
(N'The Rules of the Game',1939,110,12,N'Elegant, witty, and increasingly bitter, this French ensemble drama observes privilege at play in a country house. Its atmosphere is festive on the surface but morally anxious underneath, revealing how manners, desire, and class can turn civility into a graceful form of cruelty.'),
(N'The Third Man',1949,104,12,N'Venetian shadows, crooked streets, and a haunting musical score give this mystery its unforgettable atmosphere. It is playful, tense, and morally slippery, following friendship through a city where loyalty has become negotiable and every picturesque corner may conceal betrayal.'),
(N'All About Eve',1950,138,12,N'Sharp, glamorous, and edged with melancholy, this backstage drama fills theaters and dressing rooms with ambition. Its atmosphere is witty but watchful, exploring admiration, aging, and performance while showing how applause can make affection feel like another competition.'),
(N'Wild Strawberries',1957,92,12,N'Quietly dreamlike and reflective, this Swedish road film turns memories, dreams, and passing landscapes into an emotional reckoning. Its atmosphere is melancholy without despair, allowing an aging man to revisit regret and discover that tenderness may still be possible late in life.'),
(N'The Magnificent Seven',1960,128,12,N'Wide landscapes, spare music, and a sense of approaching danger shape this generous western. Its atmosphere is heroic but not naïve, bringing mismatched strangers together through courage, humor, and sacrifice while asking what kind of freedom is worth defending.'),
(N'8 1/2',1963,138,16,N'Playful, surreal, and emotionally restless, this Italian film drifts between memory, fantasy, and creative paralysis. Its atmosphere is glamorous yet anxious, using cinema itself as a dream room where desire, guilt, childhood, and artistic doubt refuse to stay in separate corners.'),
(N'The Battle of Algiers',1966,121,16,N'Immediate and documentary-like, this political drama creates tension through streets, crowds, surveillance, and divided loyalties. Its atmosphere is controlled but urgent, presenting rebellion and repression without easy comfort while making the city itself feel like a participant in history.'),
(N'The Exorcist',1973,132,18,N'Coldly realistic before becoming terrifying, this horror film builds dread inside ordinary domestic rooms. Its atmosphere is grave, intimate, and spiritually shaken, using medical uncertainty, family love, and ritual to make the impossible feel frighteningly close to everyday life.'),
(N'Network',1976,121,16,N'Furious, satirical, and darkly prophetic, this newsroom drama turns television into a stage for rage and spectacle. Its atmosphere crackles with energy while becoming steadily more disturbing, exposing how fear, ratings, and public confession can transform despair into profitable entertainment.'),
(N'Apocalypse Now',1979,147,18,N'Hypnotic, feverish, and morally disorienting, this war film moves through rivers, smoke, music, and oppressive heat. Its atmosphere feels like a waking nightmare in which civilization loses its outline, while violence becomes both spectacle and a terrifying journey into the self.'),
(N'Raiders of the Lost Ark',1981,115,12,N'Exuberant, suspenseful, and warmly old-fashioned, this adventure carries the pleasure of a Saturday matinee. Its atmosphere mixes ancient mystery, comic danger, romance, and relentless motion, making courage feel physical and discovery feel like an invitation to keep looking around the next corner.'),
(N'Paris, Texas',1984,145,16,N'Sun-bleached roads, empty spaces, and quiet faces give this drama a profound sense of loneliness. Its atmosphere is tender but wounded, following broken people toward reconciliation through patience, distance, and the difficult possibility that love can survive what memory has damaged.'),
(N'The Fly',1986,96,18,N'Visceral, tragic, and strangely intimate, this science-fiction horror begins with curiosity before turning transformation into a nightmare of the body. Its atmosphere is claustrophobic and mournful, making scientific ambition feel inseparable from love, fear, and the terror of losing oneself.'),
(N'Do the Right Thing',1989,120,16,N'Hot color, loud music, and a single sweltering day create the charged atmosphere of this neighborhood drama. Humor and community warmth gradually tighten into anger, showing how small grievances, structural injustice, and unresolved pride can make a familiar street feel combustible.'),
(N'Unforgiven',1992,130,16,N'Bleak, quiet, and morally haunted, this western strips heroism of its easy glow. Its open landscapes feel cold rather than liberating, while violence leaves a lasting stain on everyone involved. The atmosphere asks whether justice can exist without becoming another form of revenge.'),
(N'The Piano',1993,121,16,N'Misty shores, dark forests, and music carried through silence shape this intensely atmospheric romance. Its mood is passionate but restrained, following desire and control through a landscape where social rules feel heavy and private expression becomes a form of survival.'),
(N'Fargo',1996,98,16,N'Snowy roads and polite voices frame this darkly comic crime story with an atmosphere both absurd and chilling. Beneath the blood and awkward schemes lies a steady belief in decency, making the contrast between ordinary kindness and reckless greed especially sharp.'),
(N'The Iron Giant',1999,86,7,N'Warm, wistful, and full of retro wonder, this animated family film pairs a lonely boy with a mysterious visitor from the sky. Its atmosphere moves from playful friendship to genuine danger, finding emotional power in gentleness, choice, and the refusal to become a weapon.'),
(N'Fight Club',1999,139,18,N'Grimy, restless, and aggressively stylish, this dark drama turns alienation into a seductive fantasy of rebellion. Its atmosphere crackles with anger and dark humor before revealing deeper emptiness, questioning identity, consumer comfort, and the costs of mistaking destruction for freedom.'),
(N'Hero',2002,99,12,N'Color, silence, and choreographed movement give this Chinese wuxia film a painterly, almost dreamlike atmosphere. Its elegant action carries political weight, shifting between versions of truth while asking whether personal sacrifice can serve a peace larger than individual desire.'),
(N'Lost in Translation',2003,102,12,N'Quietly funny and steeped in nighttime melancholy, this film finds intimacy in an unfamiliar city. Neon hotels, jet lag, and unfinished conversations create an atmosphere of suspended time, where two lonely people recognize one another without needing to define what the connection means.'),
(N'There Will Be Blood',2007,158,18,N'Bleak landscapes, roaring machinery, and obsessive ambition give this historical drama an almost biblical atmosphere. Its slow intensity traces power turning into isolation, while oil, faith, and family become competing languages for a man determined to own everything around him.'),
(N'The Grand Budapest Hotel',2014,100,12,N'Whimsical, precise, and gently mournful, this comedy places courtesy and friendship inside a rapidly changing Europe. Its pastel world feels playful but fragile, preserving old rituals while history presses in. The result is a confection with a surprisingly deep taste of loss.')
) AS source (Title,ReleaseYear,RuntimeMin,MinAge,Synopsis)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Movies AS target WHERE target.Title=source.Title AND target.ReleaseYear=source.ReleaseYear);
GO

INSERT INTO dbo.MovieGenres (MovieId,GenreId)
SELECT movie.MovieId,genre.GenreId
FROM (VALUES
(N'The General',1926,N'Comedy'),(N'The General',1926,N'Action'),
(N'City Lights',1931,N'Comedy'),(N'City Lights',1931,N'Romance'),(N'City Lights',1931,N'Drama'),
(N'The Rules of the Game',1939,N'Drama'),(N'The Rules of the Game',1939,N'Comedy'),
(N'The Third Man',1949,N'Mystery'),(N'The Third Man',1949,N'Thriller'),(N'The Third Man',1949,N'Crime'),
(N'All About Eve',1950,N'Drama'),(N'All About Eve',1950,N'Comedy'),
(N'Wild Strawberries',1957,N'Drama'),
(N'The Magnificent Seven',1960,N'Western'),(N'The Magnificent Seven',1960,N'Adventure'),
(N'8 1/2',1963,N'Drama'),(N'8 1/2',1963,N'Comedy'),
(N'The Battle of Algiers',1966,N'Drama'),(N'The Battle of Algiers',1966,N'War'),
(N'The Exorcist',1973,N'Horror'),(N'The Exorcist',1973,N'Drama'),
(N'Network',1976,N'Drama'),(N'Network',1976,N'Comedy'),
(N'Apocalypse Now',1979,N'War'),(N'Apocalypse Now',1979,N'Drama'),
(N'Raiders of the Lost Ark',1981,N'Adventure'),(N'Raiders of the Lost Ark',1981,N'Action'),
(N'Paris, Texas',1984,N'Drama'),
(N'The Fly',1986,N'Horror'),(N'The Fly',1986,N'Sci-Fi'),
(N'Do the Right Thing',1989,N'Drama'),(N'Do the Right Thing',1989,N'Comedy'),
(N'Unforgiven',1992,N'Western'),(N'Unforgiven',1992,N'Drama'),
(N'The Piano',1993,N'Drama'),(N'The Piano',1993,N'Romance'),
(N'Fargo',1996,N'Crime'),(N'Fargo',1996,N'Comedy'),
(N'The Iron Giant',1999,N'Animation'),(N'The Iron Giant',1999,N'Family'),(N'The Iron Giant',1999,N'Sci-Fi'),
(N'Fight Club',1999,N'Drama'),(N'Fight Club',1999,N'Thriller'),
(N'Hero',2002,N'Action'),(N'Hero',2002,N'Adventure'),(N'Hero',2002,N'Drama'),
(N'Lost in Translation',2003,N'Drama'),(N'Lost in Translation',2003,N'Romance'),
(N'There Will Be Blood',2007,N'Drama'),(N'There Will Be Blood',2007,N'Biography'),
(N'The Grand Budapest Hotel',2014,N'Comedy'),(N'The Grand Budapest Hotel',2014,N'Adventure'),(N'The Grand Budapest Hotel',2014,N'Drama')
) AS source (Title,ReleaseYear,GenreName)
JOIN dbo.Movies AS movie ON movie.Title=source.Title AND movie.ReleaseYear=source.ReleaseYear
JOIN dbo.Genres AS genre ON genre.Name=source.GenreName
WHERE NOT EXISTS (SELECT 1 FROM dbo.MovieGenres AS target WHERE target.MovieId=movie.MovieId AND target.GenreId=genre.GenreId);
GO
