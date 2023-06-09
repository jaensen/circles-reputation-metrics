# Circles data
## Sources
### Indexer-DB dump
A compressed db dump of the circles network, it's balances and transfers can be downloaded here: https://rpc.helsinki.circlesubi.id/pathfinder-db/bak_indexer_db_20230529.dump
It can be restored to the postgres db `index` with `pg_restore -U postgres -v -d index < ./bak_indexer_db_20230529.dump`.

The database schema is visualized at: https://github.com/CirclesUBI/blockchain-indexer#indexed-events

The definitions of the following views provide a good insight into how the data is structured:
* crc_ledger_2
* crc_current_trust_2

During normal use, there are cache tables that always contain the current state of the trust graph and balances:
* cache_crc_balances_by_safe_and_token
* cache_crc_current_trust

### Circles-ubi subgraph
Definition: https://github.com/CirclesUBI/circles-subgraph  
Endpoint: https://api.thegraph.com/subgraphs/name/circlesubi/circles-ubi/

### Group-currency subgraph
This is a fork of the above subgraph with the addition of group currencies.
It's Circles part is not up-to-date, only use it to query group currency data.

Definition: https://github.com/jaensen/BN-circles-subgraph  
Endpoint: https://api.thegraph.com/subgraphs/name/laimejesus/circles-local

Diff of the group currency part: https://github.com/CirclesUBI/circles-subgraph/compare/main...jaensen:BN-circles-subgraph:dev

### Pathfinder db dump
Download: https://rpc.circlesubi.id/pathfinder-db/capacity_graph.db   
Binary format description: https://hackmd.io/Gg04t7gjQKeDW2Q6Jchp0Q#load_safes_binaryfile-ltpathgt

### Circles.garden api
You can query up to 50 profiles by their circles safe address in one request with the following url schema:
```
https://api.circles.garden/api/users/?address[]=0x1....&address[]=0x2....
```
[circles_avatar_hashes_20230609.csv](csv/20230609_circles_avatar_hashes.csv) contains the avatar image hashes
for each user. They can be used to find users with duplicate avatar images.