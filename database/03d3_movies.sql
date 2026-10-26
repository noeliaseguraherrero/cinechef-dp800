/*==============================================================
  CineChef - Fase 3d: películas, tanda 3 de 4
  25 películas nuevas; no modifica las tandas anteriores.
  Sinopsis originales y relaciones por título, año y género.
==============================================================*/
USE CineChefDB;
GO

INSERT INTO dbo.Movies (Title, ReleaseYear, RuntimeMin, MinAge, Synopsis)
SELECT source.Title, source.ReleaseYear, source.RuntimeMin, source.MinAge, source.Synopsis
FROM (VALUES
(N'Nosferatu',1922,94,16,N'Haunting, expressionistic, and steeped in shadow, this silent horror film makes fear feel architectural. Empty streets, angular rooms, and an inhuman presence create an atmosphere of plague and fatalism, while its strange beauty keeps dread suspended between dream and nightmare.'),
(N'M',1931,99,16,N'Grim, tense, and urban, this German thriller turns a city into a nervous collective mind. Whistling, stairwells, and crowded streets create an atmosphere of suspicion as ordinary people become investigators, judges, and frightened witnesses searching for order amid fear.'),
(N'The Wizard of Oz',1939,102,0,N'Colorful, musical, and warmly nostalgic, this fantasy moves from familiar domestic grayness into a world of dazzling invention. Its atmosphere balances wonder with gentle danger, giving friendship, courage, and homecoming a timeless emotional glow for viewers of every age.'),
(N'Sunset Boulevard',1950,110,16,N'Glamorous and poisonous, this Hollywood noir drifts through faded mansions, theatrical memories, and sharp social observation. Its atmosphere is decadent yet lonely, suggesting that fame can preserve an image while leaving the person inside it stranded in darkness.'),
(N'Rashomon',1950,88,12,N'Mysterious and rain-soaked, this Japanese drama makes truth feel fractured by memory, pride, and self-protection. The ruined gate and forest become spaces of moral uncertainty, creating an atmosphere where every confession sounds persuasive and honesty remains painfully difficult.'),
(N'Vertigo',1958,128,12,N'Dreamlike, obsessive, and colored by longing, this psychological mystery turns San Francisco into a landscape of vertigo and emotional repetition. Its atmosphere is elegant but troubled, drawing romance toward fixation while asking whether love can survive the desire to remake another person.'),
(N'Lawrence of Arabia',1962,228,12,N'Vast deserts and swelling music give this historical epic a hypnotic, sun-struck grandeur. Beneath the spectacle lies a mood of isolation and uncertainty, as charisma, empire, and identity blur across a landscape that makes human ambition seem both magnificent and fragile.'),
(N'Dr. Strangelove',1964,95,16,N'Coldly hilarious and increasingly alarming, this political satire turns military procedure into absurd catastrophe. Its clipped rooms, rigid language, and manic performances create an atmosphere where rational systems reveal their madness, making laughter feel uncomfortably close to panic.'),
(N'The Good, the Bad and the Ugly',1966,161,16,N'Dusty landscapes, dry wit, and operatic music give this western an expansive, playful tension. Its world is morally slippery but visually grand, moving between greed, survival, and uneasy partnership while every standoff feels like a ritual performed beneath a merciless sun.'),
(N'One Flew Over the Cuckoo''s Nest',1975,133,16,N'Rebellious, funny, and gradually heartbreaking, this drama turns an institution into a pressure cooker of rules and personalities. Its atmosphere begins with mischievous energy before tightening into tragedy, defending individuality while showing how easily authority can disguise itself as care.'),
(N'Taxi Driver',1976,114,18,N'Night streets, neon reflections, and a restless inner voice create the feverish atmosphere of this urban character study. The city feels lonely and contaminated by violence, while isolation turns observation into obsession and a desire for cleansing into something deeply dangerous.'),
(N'Stalker',1979,162,16,N'Slow, mysterious, and hypnotically contemplative, this science-fiction journey crosses ruined spaces toward a place shaped by desire. Wet corridors, abandoned landscapes, and long silences create an atmosphere of spiritual uncertainty where hope, fear, and belief become difficult to separate.'),
(N'Raging Bull',1980,129,18,N'Brutal, intimate, and visually stark, this boxing drama studies pride through sweat, violence, and domestic silence. Its black-and-white atmosphere feels like a damaged memory, tracing how jealousy and self-punishment can turn strength into isolation long after the applause fades.'),
(N'Das Boot',1981,149,16,N'Claustrophobic and relentlessly suspenseful, this war film traps its crew inside steel, darkness, and mechanical danger. The submarine becomes a pressure chamber where camaraderie competes with fear, creating an atmosphere that respects endurance while stripping heroism of its comforting shine.'),
(N'Amadeus',1984,160,12,N'Lush, theatrical, and filled with envy, this historical drama surrounds music with candlelight, costume, and emotional excess. Its atmosphere is playful on the surface but tragic underneath, exploring genius, resentment, and the painful desire to be recognized by a world that seems unfairly arranged.'),
(N'The Untouchables',1987,119,16,N'Stylish, muscular, and morally direct, this crime drama turns Prohibition-era Chicago into a world of rain, sharp suits, and sudden violence. Its atmosphere is heroic but uneasy, balancing loyalty and sacrifice against a criminal empire protected by fear and corruption.'),
(N'Akira',1988,124,16,N'Electrifying and dystopian, this animated film fills Neo-Tokyo with neon, speed, political unrest, and unstable power. Its atmosphere is simultaneously exhilarating and terrifying, making adolescence feel physically explosive while the city strains beneath technology, violence, and unresolved trauma.'),
(N'Goodfellas',1990,146,18,N'Fast, seductive, and corrosively funny, this crime film makes a criminal lifestyle feel glamorous before exposing its rot. Music, motion, and sudden brutality create an atmosphere of exhilaration sliding into paranoia, where loyalty becomes performance and friendship is measured by usefulness.'),
(N'The Silence of the Lambs',1991,118,18,N'Controlled, intelligent, and deeply unnerving, this thriller builds dread through interviews, corridors, and withheld information. Its atmosphere is cold but purposeful, following courage through a world of manipulation while giving silence, politeness, and attention an almost physical menace.'),
(N'Jurassic Park',1993,127,7,N'Wonder and danger share the same lush landscape in this family adventure. The first glimpses of living dinosaurs create pure amazement before the park becomes a storm of suspense, combining playful discovery, scientific arrogance, and the thrilling vulnerability of people facing the impossible.'),
(N'Heat',1995,170,16,N'Cool, nocturnal, and emotionally restrained, this crime drama moves through Los Angeles streets with a sense of professional ritual. Its atmosphere is sleek but lonely, linking two disciplined men through mutual recognition while violence steadily erodes the lives they protect.'),
(N'The Truman Show',1998,103,7,N'Bright, gentle, and increasingly uncanny, this comedy-drama turns a perfect seaside town into a stage with invisible walls. Its atmosphere shifts from reassuring routine to existential unease, making curiosity and authenticity feel courageous in a world designed to keep one person comfortable.'),
(N'City of God',2002,130,18,N'Vivid, kinetic, and morally restless, this Brazilian crime drama races through neighborhoods shaped by poverty, ambition, and violence. Its energy can feel exhilarating before becoming devastating, using photography and memory to show how stories survive even when childhood is swallowed by power.'),
(N'Eternal Sunshine of the Spotless Mind',2004,108,12,N'Tender, inventive, and bittersweet, this romance moves through memories as they fracture and disappear. Its atmosphere is intimate and dreamlike, finding humor in emotional mess while asking whether pain should be erased when it is also part of what makes love meaningful.'),
(N'The Dark Knight',2008,152,16,N'Brooding, tense, and morally serious, this superhero crime drama turns a modern city into a test of fear, order, and conscience. Its atmosphere grows darker as spectacle gives way to difficult choices, asking what people will sacrifice when symbols become more powerful than institutions.')
) AS source (Title,ReleaseYear,RuntimeMin,MinAge,Synopsis)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Movies AS target WHERE target.Title=source.Title AND target.ReleaseYear=source.ReleaseYear);
GO

INSERT INTO dbo.MovieGenres (MovieId,GenreId)
SELECT movie.MovieId,genre.GenreId
FROM (VALUES
(N'Nosferatu',1922,N'Horror'),(N'Nosferatu',1922,N'Fantasy'),
(N'M',1931,N'Thriller'),(N'M',1931,N'Crime'),
(N'The Wizard of Oz',1939,N'Fantasy'),(N'The Wizard of Oz',1939,N'Family'),(N'The Wizard of Oz',1939,N'Musical'),
(N'Sunset Boulevard',1950,N'Drama'),(N'Sunset Boulevard',1950,N'Crime'),
(N'Rashomon',1950,N'Drama'),(N'Rashomon',1950,N'Mystery'),
(N'Vertigo',1958,N'Thriller'),(N'Vertigo',1958,N'Romance'),(N'Vertigo',1958,N'Mystery'),
(N'Lawrence of Arabia',1962,N'Adventure'),(N'Lawrence of Arabia',1962,N'Biography'),(N'Lawrence of Arabia',1962,N'War'),
(N'Dr. Strangelove',1964,N'Comedy'),(N'Dr. Strangelove',1964,N'War'),
(N'The Good, the Bad and the Ugly',1966,N'Western'),(N'The Good, the Bad and the Ugly',1966,N'Adventure'),
(N'One Flew Over the Cuckoo''s Nest',1975,N'Drama'),
(N'Taxi Driver',1976,N'Crime'),(N'Taxi Driver',1976,N'Drama'),
(N'Stalker',1979,N'Sci-Fi'),(N'Stalker',1979,N'Drama'),
(N'Raging Bull',1980,N'Biography'),(N'Raging Bull',1980,N'Drama'),
(N'Das Boot',1981,N'War'),(N'Das Boot',1981,N'Drama'),
(N'Amadeus',1984,N'Biography'),(N'Amadeus',1984,N'Drama'),(N'Amadeus',1984,N'Musical'),
(N'The Untouchables',1987,N'Crime'),(N'The Untouchables',1987,N'Drama'),
(N'Akira',1988,N'Animation'),(N'Akira',1988,N'Sci-Fi'),(N'Akira',1988,N'Action'),
(N'Goodfellas',1990,N'Crime'),(N'Goodfellas',1990,N'Drama'),
(N'The Silence of the Lambs',1991,N'Thriller'),(N'The Silence of the Lambs',1991,N'Crime'),(N'The Silence of the Lambs',1991,N'Horror'),
(N'Jurassic Park',1993,N'Adventure'),(N'Jurassic Park',1993,N'Sci-Fi'),(N'Jurassic Park',1993,N'Family'),
(N'Heat',1995,N'Crime'),(N'Heat',1995,N'Thriller'),
(N'The Truman Show',1998,N'Comedy'),(N'The Truman Show',1998,N'Drama'),(N'The Truman Show',1998,N'Sci-Fi'),
(N'City of God',2002,N'Crime'),(N'City of God',2002,N'Drama'),
(N'Eternal Sunshine of the Spotless Mind',2004,N'Romance'),(N'Eternal Sunshine of the Spotless Mind',2004,N'Sci-Fi'),(N'Eternal Sunshine of the Spotless Mind',2004,N'Drama'),
(N'The Dark Knight',2008,N'Action'),(N'The Dark Knight',2008,N'Crime'),(N'The Dark Knight',2008,N'Drama')
) AS source (Title,ReleaseYear,GenreName)
JOIN dbo.Movies AS movie ON movie.Title=source.Title AND movie.ReleaseYear=source.ReleaseYear
JOIN dbo.Genres AS genre ON genre.Name=source.GenreName
WHERE NOT EXISTS (SELECT 1 FROM dbo.MovieGenres AS target WHERE target.MovieId=movie.MovieId AND target.GenreId=genre.GenreId);
GO
