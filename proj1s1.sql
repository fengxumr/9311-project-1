-- COMP9311 17s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1: buildings that have more than 30 rooms
create or replace view Q1(unswid, name)
as
select distinct buildings.unswid, buildings.name
from buildings, rooms
where buildings.id = rooms.building
group by buildings.unswid,buildings.name
having count(rooms.id) > 30
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q2: get details of the current Deans of Faculty
create or replace view Q2(name, faculty, phone, starting)
as
select distinct people.name, orgunits.longname, staff.phone, affiliations.starting
from people, orgunits, staff, affiliations, staff_roles, orgunit_types
where people.id = affiliations.staff
and people.id = staff.id
and orgunits.utype = orgunit_types.id
and orgunits.id = affiliations.orgunit
and affiliations.role = staff_roles.id
and staff_roles.name = 'Dean'
and affiliations.ending is null
and orgunit_types.name = 'Faculty'
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q3: get details of the longest-serving and shortest-serving current Deans of Faculty
create or replace view Q3(status, name, faculty, starting)
as
select 'Shortest serving' as status, name, faculty, starting
from q2
where starting = (select max(starting) from q2)
union
select 'Longest serving' as status, name, faculty, starting
from q2
where starting = (select min(starting) from q2)
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q4 UOC/ETFS ratio
create or replace view Q4(ratio,nsubjects)
as
select cast(uoc/eftsload as decimal(4,1)), count(code)
from subjects where eftsload != 0
group by cast(uoc/eftsload as decimal(4,1))
--... SQL statements, possibly using other views/functions defined by you ...
;



