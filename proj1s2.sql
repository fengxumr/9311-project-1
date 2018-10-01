-- COMP9311 17s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q5:

create or replace view Q5a(num) as
select count(program_enrolments.student) from students, semesters, program_enrolments, streams, stream_enrolments
where students.id = program_enrolments.student
and semesters.id = program_enrolments.semester
and streams.id = stream_enrolments.stream
and stream_enrolments.partof = program_enrolments.id
and students.stype = 'intl'
and semesters.year = '2010'
and semesters.term = 'S1'
and streams.code = 'SENGA1';

create or replace view Q5b(num) as
select count(students.id) from acad_object_groups, program_enrolments, program_group_members, programs, semesters, students
where acad_object_groups.id = program_group_members.ao_group 
and program_group_members.program = programs.id 
and programs.id = program_enrolments.program 
and program_enrolments.student = students.id 
and program_enrolments.semester = semesters.id
and students.stype = 'local'
and semesters.year = '2010'
and semesters.term = 'S1'
and acad_object_groups.name = '3978 - Computer Science';

create or replace view Q5c(num) as
select count(students.id) from orgunits, program_enrolments, programs, semesters, students
where orgunits.id = programs.offeredby
and programs.id = program_enrolments.program
and program_enrolments.student = students.id
and program_enrolments.semester = semesters.id
and orgunits.name = 'Faculty of Engineering'
and semesters.year = '2010'
and semesters.term = 'S1';

-- Q6:

create or replace function Q6(text) 
returns text as $$
declare 
 a text; 
 b text;
begin
 select code, name into a, b from subjects where code = $1;
 return a || ' ' || b;
end;
$$ language plpgsql;


-- Q7:

create or replace view Q7(year, term, perc_growth) as
with temp as
(
select semesters.year as y, semesters.term as t, count(course_enrolments.student)::numeric(4, 2) as q
from course_enrolments, courses, semesters, subjects
where course_enrolments.course = courses.id
and courses.subject = subjects.id
and courses.semester = semesters.id
and subjects.name = 'Database Systems'
group by semesters.year, semesters.term, semesters.starting
order by semesters.starting
)
select y, t, r::numeric(4, 2) from (select y, t, q/lag(q) over (order by y, t) as r from temp) as base where r is not null;

-- Q8:

create or replace view temp_1(subject, full_subject) as
select courses.subject, subjects.code || ' ' || subjects.name
from courses, subjects
where courses.subject = subjects.id
group by courses.subject, subjects.code, subjects.name
having count(courses.id) >= 20;

create or replace view temp_2(student_qty, subject, course, starting) as
select count(distinct course_enrolments.student), courses.subject, courses.id, semesters.starting
from course_enrolments, courses, semesters
where course_enrolments.course = courses.id
and courses.semester = semesters.id
group by courses.id, courses.subject, semesters.starting;

create or replace view temp_3(full_subject, student_qty, course, starting) as
select full_subject, student_qty, course, starting
from temp_1
left outer join temp_2
on temp_1.subject = temp_2.subject;

create or replace view temp_4(full_subject, course, student_qty, row) as
select full_subject, course, student_qty,
row_number() over (partition by full_subject order by (CURRENT_DATE - starting))
from temp_3;

create or replace view temp_5(full_subject, course, student_qty) as
select full_subject, course, student_qty
from temp_4
where row <= 20;

create or replace view temp_6(full_subject, course, status) as
select full_subject, course, 
case when student_qty < 20 and student_qty >= 0 then 0
when student_qty is null then 0 
else 1 end
from temp_5;

create or replace view Q8(subject) as
select full_subject from temp_6
group by full_subject
having sum(status) = 0;

-- Q9:

create or replace view temp_q9_1 as
select mark, year, term
from course_enrolments, courses, semesters, subjects
where course_enrolments.course = courses.id
and courses.subject = subjects.id
and courses.semester = semesters.id
and subjects.name = 'Database Systems';

create or replace view temp_q9_2 as
select year, term, 
case when mark >= 50 then 1.00
when mark >= 0 and mark < 50 then 0.00
end as status
from temp_q9_1;

create or replace view temp_q9_3 as
select year, term, cast(sum(status)/count(status) as numeric(4, 2)) as pass_rate
from temp_q9_2
group by year, term;

create or replace view temp_q9_4 as
select year, term, pass_rate as s1_pass_rate 
from temp_q9_3
where term = 'S1';

create or replace view temp_q9_5 as
select year, term, pass_rate as s2_pass_rate 
from temp_q9_3
where term = 'S2';

create or replace view Q9(year, s1_pass_rate, s2_pass_rate)  as
select substring(cast(temp_q9_4.year as text) from 3 for 2), temp_q9_4.s1_pass_rate, temp_q9_5.s2_pass_rate
from temp_q9_4
inner join temp_q9_5
on temp_q9_4.year = temp_q9_5.year
order by temp_q9_4.year;

-- Q10:

create or replace view temp_q10_1 as
select 'z' || people.unswid as zid, regexp_replace(given, ' .*', '') || ' ' || family as name, year, term, subject, course,
case when mark < 50 then 1 end as status
from course_enrolments, courses, people, semesters, subjects
where course_enrolments.student = people.id
and course_enrolments.course = courses.id
and courses.subject = subjects.id
and courses.semester = semesters.id
and (term = 'S1' or term = 'S2')
and (year >= 2002 or year <= 2013)
and subjects.code like 'COMP93%';

create or replace view temp_q10_2 as
select code, subject from 
(
select distinct subject, code, year, term 
from courses, semesters, subjects
where courses.semester = semesters.id
and courses.subject = subjects.id
and (term = 'S1' or term = 'S2')
and (year >= 2002 or year <= 2013)
and subjects.code like 'COMP93%'
) 
as base
group by code, subject
having count(year) = 24;

create or replace view temp_q10_3 as
select zid, name, temp_q10_2.code, status
from temp_q10_2
inner join temp_q10_1
on temp_q10_2.subject = temp_q10_1.subject
where status is not null;

create or replace view temp_q10_4 as
select count(*) as qty
from temp_q10_2;

create or replace view temp_q10_5 as
select *
from temp_q10_3
cross join
temp_q10_4;

create or replace view Q10(zid, name) as
select zid, name
from temp_q10_5
group by zid, name, qty
having count(distinct code) = qty;

