Constraints (ensure integrity)
-- USERS
ALTER TABLE Users ADD UNIQUE (username), ADD UNIQUE (email),
  ADD CONSTRAINT chk_role CHECK (role IN ('teacher','student'));

-- VERSES
ALTER TABLE QuranVerses ADD UNIQUE (surah_number, verse_number);

-- LESSON-VERSE
ALTER TABLE LessonQuranVerse
  ADD UNIQUE (lesson_id, verse_id),
  ADD UNIQUE (lesson_id, verse_order);

-- LESSONS
ALTER TABLE Lessons
  ADD CONSTRAINT chk_lang CHECK (language IN ('Swahili','Arabic'));

-- EXERCISES
ALTER TABLE Exercises
  ADD CONSTRAINT chk_ex_type CHECK (type IN ('quiz','fill-in-the-blank','true-false'));

-- PROGRESS
ALTER TABLE ProgressTracking
  ADD UNIQUE (user_id, lesson_id),
  ADD CONSTRAINT chk_status CHECK (completion_status IN ('completed','in progress','not started'));

-- SCHEDULER
ALTER TABLE Scheduler
  ADD CONSTRAINT chk_sched_status CHECK (Status IN ('schedulled','completed','missed','cancelled')),
  ADD CONSTRAINT chk_times CHECK (Start_time < End_time);

Seed Test Data
INSERT INTO Users VALUES
(1,'teacher1','x','t1@example.com','teacher',NULL,NOW(),NOW()),
(2,'student1','x','s1@example.com','student',NULL,NOW(),NOW());

INSERT INTO Lessons VALUES
(10,'Tajweed Basics','Makharij rules','Arabic',NOW(),NOW());

INSERT INTO QuranVerses VALUES
(100,1,1,'بسم الله','Kwa jina la Mungu','Maelezo','/a1.mp3'),
(101,1,2,'الحمد لله','Sifa zote za Mungu','Maelezo','/a2.mp3');

INSERT INTO LessonQuranVerse VALUES
(1000,10,100,1),(1001,10,101,2);

INSERT INTO Exercises VALUES
(2000,10,'Makharij Quiz','quiz','{...}',NOW());

INSERT INTO ProgressTracking VALUES
(3000,2,10,'in progress',60,NOW());

INSERT INTO ExerciseAnswers VALUES
(5000,2000,2,'{...}',true,NOW());

INSERT INTO Logs VALUES
(6000,2,'lesson_start',NOW(),10,NULL,'Started lesson');

INSERT INTO Scheduler VALUES
(7000,2,'student','Attend Tajweed',10,CURDATE(),
 TIMESTAMP(CURDATE(),'10:00:00'),TIMESTAMP(CURDATE(),'11:00:00'),
 TIMESTAMP(CURDATE(),'09:30:00'),'schedulled',3000);

Verse order

SELECT v.surah_number,v.verse_number
FROM LessonQuranVerse lv JOIN QuranVerses v ON v.verse_id=lv.verse_id
WHERE lv.lesson_id=10 ORDER BY lv.verse_order;


Student lesson view

SELECT l.title,pt.completion_status,pt.score,
 COUNT(DISTINCT lv.verse_id) AS verses,
 COUNT(DISTINCT e.exercise_id) AS exercises
FROM Lessons l
LEFT JOIN ProgressTracking pt ON pt.lesson_id=l.lesson_id AND pt.user_id=2
LEFT JOIN LessonQuranVerse lv ON lv.lesson_id=l.lesson_id
LEFT JOIN Exercises e ON e.lesson_id=l.lesson_id
WHERE l.lesson_id=10 GROUP BY l.title,pt.completion_status,pt.score;


Prevent duplicates

-- Should fail (duplicate verse in same lesson)
INSERT INTO LessonQuranVerse VALUES (9999,10,100,3);


Detect schedule overlaps

SELECT s1.Schedule_id,s2.Schedule_id
FROM Scheduler s1 JOIN Scheduler s2
 ON s1.User_id=s2.User_id AND s1.Schedule_id<s2.Schedule_id
 AND s1.Start_time < s2.End_time AND s2.Start_time < s1.End_time
WHERE s1.User_id=2;


Answers correctness rate

SELECT e.exercise_id,
 SUM(ea.is_correct=1) AS correct, COUNT(*) AS attempts,
 ROUND(100*SUM(ea.is_correct=1)/COUNT(*),1) AS pct_correct
FROM Exercises e
LEFT JOIN ExerciseAnswers ea ON ea.exercise_id=e.exercise_id
WHERE e.lesson_id=10 GROUP BY e.exercise_id;

4. Business Rules to Validate

Only students submit answers:

SELECT ea.answer_id FROM ExerciseAnswers ea
JOIN Users u ON u.user_id=ea.user_id WHERE u.role<>'student';


Reminder before start:

SELECT Schedule_id FROM Scheduler WHERE Reminder_time>=Start_time;


Auto-mark missed lessons:

SELECT Schedule_id FROM Scheduler WHERE Status='missed' AND End_time<NOW();