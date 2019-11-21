drop procedure if exists fix_service_sla;

DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `fixsla`(IN n bigint(20) unsigned)
begin
		declare _nextid int;
        declare descr varchar(255);
		declare c_triggerid int;
		declare c_serviceid int;
        declare c_sname varchar(128);
        declare _continue int;
		declare _s bigint(20) unsigned;
        declare _c int(11);
        declare _t int(11);
		declare cur cursor for select triggerid, serviceid, name FROM tmp;
		declare continue handler for not found
			set _continue = 1;
            
		set @_nextid = (select nextid from ids where table_name = 'service_alarms' and field_name = 'servicealarmid') + 1;
		
        begin

			select concat("scanning service hierarchy starting at node: ", n) as "";
			drop table if exists tmp;
			create temporary table tmp as (
				select * from (
					select s.triggerid, s.serviceid, s.name from services s 
						left join triggers t on t.triggerid = s.triggerid

					where s.serviceid in (select  servicedownid
					from    (select * from services_links
							 order by serviceupid) sl_sorted,
							(select @pv := n) initialisation
					where   find_in_set(serviceupid, @pv)
					and     length(@pv := concat(@pv, ',', servicedownid)))

					and s.triggerid is not NULL
				) aa
			);
		end;
        
		begin
			drop table if exists tmp2;
			create temporary table tmp2 (s bigint(20) unsigned, c int(11), t int(11));
			set _continue = 0;
			open cur;
			repeat
				fetch cur into c_triggerid, c_serviceid, c_sname;
				set @descr = (select description from triggers t where t.triggerid = c_triggerid);
				insert into tmp2 (s, c, t) select c_serviceid, e.clock, if (e.value=1,5,0) from events e where e.objectid = c_triggerid;
				select concat("service node: [", c_sname, "/", c_serviceid, "] trigger: [", @descr, "]. events inserted: " , row_count()) as "completion notice:";
                until _continue = 1
			end repeat;
			close cur;
        end;
        
        begin
			declare cur2 cursor for select s, c, t FROM tmp2;
			set _continue = 0;
        	open cur2;
			repeat
				fetch cur2 into _s, _c, _t;
				insert into service_alarms (servicealarmid, serviceid, clock, `value`) values (@_nextid, _s, _c, _t);
				set @_nextid = @_nextid + 1;
                until _continue = 1
			end repeat;
			close cur2;
        end;
        
        update ids set nextid = @_nextid where table_name = 'service_alarms' and field_name = 'servicealarmid';
        
        -- remove all leftovers
        drop table tmp;
        drop table tmp2;
	end$$
DELIMITER ;
