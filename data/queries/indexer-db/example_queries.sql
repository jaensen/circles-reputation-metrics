-- List all signups:
select hash as signup_transaction_hash
     , block_number
     , timestamp
     , "user" as circles_account_address
     , token as circles_token
from crc_all_signups;

-- Personal accounts have an own CRC 'token':
select * from crc_all_signups where token is not null;

-- Organizations don't have an own 'token':
select * from crc_all_signups where token is null;

-- Get all circles transfers of a user (in/out):
------------------------------------------------
select *
from crc_safe_timeline_2
where safe_address = lower('0xDE374ece6fA50e781E81Aac78e811b33D16912c7')
  and type = 'CrcHubTransfer';


-- Get all trust events of a user (in/out):
-------------------------------------------
select *
from crc_safe_timeline_2
where safe_address = lower('0xDE374ece6fA50e781E81Aac78e811b33D16912c7')
  and type = 'CrcTrust';


-- Get all token holdings of a user (CRC as well as any other ERC20):
---------------------------------------------------------------------
select *
from cache_crc_balances_by_safe_and_token
where safe_address = lower('0xDE374ece6fA50e781E81Aac78e811b33D16912c7')
  and balance > 0;

-- All current trust edges:
---------------------------------------------------------
select "user", can_send_to, "limit"
from cache_crc_current_trust
where "limit" > 0;


-- Find the interval at which a user requests UBI:
--------------------------------------------------
--   Given the user's address, find all transfers of UBI to the user's address.
--   The user's Circles token address can be found in the Signup event.
with ubi_minting as (
    select s."user", t.block_number, t.value
    from erc20_transfer_2 t
             join crc_signup_2 s on s."user" = t."to"
    where s."user" = lower('0xDE374ece6fA50e781E81Aac78e811b33D16912c7')
      and t.token = s.token
      and "from" = '0x0000000000000000000000000000000000000000'
    order by t.block_number desc
)
select ubi_minting.*
     , ubi_minting.block_number - lag(ubi_minting.block_number, 1)
                                  over (order by ubi_minting.block_number) as blocks_since_last_request
from ubi_minting;


-- Find the interval at which a user trusts other users (in blocks):
--------------------------------------------------------------------
with expressed_trust_events as (
    select s."user", t.block_number
    from crc_all_signups s
             join crc_trust_2 t on t.can_send_to = s."user" and "limit" > 0
    where s."user" = lower('0xDE374ece6fA50e781E81Aac78e811b33D16912c7')
), expressed_trust_intervals as (
    select "user"
         , block_number
         , block_number - lag(block_number, 1)
                          over (order by block_number) as blocks_since_last_trust
    from expressed_trust_events
)
select *
from expressed_trust_intervals;


-- Find the incoming/outgoing trust connection ratio of each user:
------------------------------------------------------------------
--   The ratio is greater than one if a user has more outgoing trust connections than incoming.
with outgoing_trust as (
    select c."user", count(*) as incoming_trust_count
    from crc_signup_2
             join crc_current_trust_2 c on crc_signup_2."user" = c."can_send_to"
    group by c."user"
), incoming_trust as (
    select c."user", count(*) as outgoing_trust_count
    from crc_signup_2
             join crc_current_trust_2 c on crc_signup_2."user" = c."user"
    group by c."user"
), trust_ratio as (
    select it."user"
         , coalesce(outgoing_trust_count, 0)                  as outgoing_trust_count
         , coalesce(incoming_trust_count, 0)                  as incoming_trust_count
         , outgoing_trust_count::float / incoming_trust_count as ratio
    from incoming_trust it
             left join outgoing_trust ot on ot."user" = it."user"
)
select *
from trust_ratio;

-- Find the ratio of rejected to rejecting trust connections of each user:
---------------------------------------------------------------------------
--   The ratio is greater than one if a user was more often rejected than rejecting.
with rejecting as (
    select s."user", count(*) as rejecting_count
    from crc_signup_2 s
             join crc_trust_2 t on t.can_send_to = s."user" and t."limit" = 0
    group by s."user"
), rejected as (
    select s."user", count(*) as rejected_count
    from crc_signup_2 s
             join crc_trust_2 t on t."address" = s."user" and t."limit" = 0
    group by s."user"
), rejection_ratio as (
    select rejecting."user"
         , coalesce(rejecting_count, 0) as rejecting_count
         , coalesce(rejected_count, 0) as rejected_count
         , coalesce(rejected_count::float / rejecting_count, 0) as ratio
    from rejecting
             left join rejected on rejected."user" = rejecting."user"
)
select *
from rejection_ratio;

-- Find all HubTransfers that bundle single single transitive transfer steps
select ht."from", ht."to", ht.value, t."from", t."to", t.token, t.value
from crc_hub_transfer_2 ht
         join erc20_transfer_2 t on t."hash" = ht."hash";