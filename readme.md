# Reputation and trust indicators in Circles
## Summary
This document explores different indicators for each Circles primitive that could be used to build a reputation and recommendation system. It highlights why trust and reputation matter in the Circles ecosystem and what data is available to gauge them.

## Introduction

In the most basic context of Circles, trust can be defined as the "confidence that an individual possesses only one UBI-receiving Circles account." Trust is crucial to Circles, as users can only receive tokens they trust and send tokens that the recipient trusts. To prevent negative surprises, it's essential for users to understand the importance of trust relationships within the system.

Circles' architecture allows the Hub Contract to exchange a user's tokens for an equal amount of other tokens, provided that the user has previously expressed trust in those tokens. This type of transaction, known as a 'hubTransfer,' enables users who haven't directly trusted each other to conduct transactions.

However, if a user were to trust random individuals at an event they attended, for example, these people could then use a 'hubTransfer' to exchange their tokens for the user's tokens. If one of these random individuals had created a fake account, the trust connection could be exploited to swap fake Circles tokens for genuine ones. As a result, the user would be left with worthless tokens that no one else trusts.

Various projects, such as Proof of Humanity, Humanode, and Worldcoin, attempt to establish this confidence using biometric or similar methods. In contrast, Circles adopts the web of trust approach at its core and enables the creation of groups on top that can be gated by such mechanisms.

The ideal scenario for forming a Circles trust relationship involves two people who know each other well and meet in person to exchange their addresses, for example, via QR code. Realistically, many trust relationships will be formed online, where it's easier to phish or impersonate someone.

## Evidence

Since the Circles contracts have been deployed, there have been numerous attempts to impersonate legitimate users to trick people into trusting a fake account. One of the most obvious examples, which should serve as a case study here, is shown below:

There are two users named 'Martin' and 'martin' with the same profile picture on https://circles.garden:
* https://circles.garden/profile/0x42cEDde51198D1773590311E2A340DC06B24cB37
* https://circles.garden/profile/0x92211B92b9da8340715CAeCB6DD4A1277353D819

Only the first (uppercase) 'Martin' is real. The other one tries to trick people into trusting the fake account.

Without further context, it's hard for people to detect that they didn't trust the real person. This has led 22 people (there might be fakes within that as well) to trust the fake account.

There are many more accounts following the same schema. These accounts could be used as a starting point to define a fake account for the time being.  

A list of all users with duplicate avatars can be found here: [data/csv/20230609_users_with_duplicate_avatars.csv](data/csv/20230609_users_with_duplicate_avatars.csv).  
The original users of the avatars are listed in:  [data/csv/20230609_original_users_of_avatar.csv](data/csv/20230609_original_users_of_avatar.csv).

## Exploration

A key factor in helping users make informed decisions about whom to trust is understanding the connections between individuals. For Circles, there are two primary aspects to consider when examining a user's connections:
* The trust relations a user has or had
* The payment paths (either of historical or a simulated transactions) of a user

Another factor are organizations (e.g. a DAO or Group Token), which can create own rules for membership and trust. Finally, the user's behavior plays a big role in estimating the trustworthiness of that user.

### Trust relations
There are two distinct types of users in the Circles system, each with different behaviors: individuals and organizations. Organizations do not have their own tokens unless they are Groups, in which case the registered organization itself is an instance of the Circles Group Currency Token. Additionally, individuals cannot trust organizations, but organizations can trust individuals. This distinction in user types can influence trust relationships and transaction patterns.

Users can trust others by calling the trust function on the Circles Hub Contract, emitting a `Trust(address canSendTo, address user, uint256 limit)` event. This event can be read as *canSendTo -trusts-> user*.

These events allow for the creation of a trust relations graph for further analysis.

#### Points of interest
* Growth patterns: At which rate are new trust relations created? At which removed?
* Contact overlap: Do I know people who trust the same person?
* Trust clusters: Does the person belong to an identifiable/trustworthy group?
* Incoming vs. outgoing trust ratio: Is the person trusted by many (other trustworthy) people, is the ratio very unbalanced?
* Long-lasting relations: Is the majority of trust relations long-lasting after creation?
* High revocation rate: Is trust to a person often revoked?
* Trusted by other reputable users: Is the person trusted by other reputable users or groups?

### Payment paths
Payment paths are calculated by the pathfinder for each Circles `hubTransfer`. The path descibes the 'swaps', the Circles Hub must do in order to transfer a specific amount of Circles from User A to User B along their trust relations. Payment paths are DAGs with one source and sink each.

They are especially interesting because besides the source, sink, time and amount, they also encode a "frozen" part of the trust graph.

#### Historical transactions
Each successful `hubTransfer` call emits a `HubTransfer(address from, address to, uint256 amount)` event, summarizing the individual ERC20 transfers it comprises. Each ERC20 transfer still emits the standard `Transfer(address from, address to, uint256 amount)` event. These events can be used to reconstruct the full payment path of a past transaction.

Example: https://blockscout.com/xdai/mainnet/tx/0x8df9382979d08b022ed3510323931e1cd51f077c03ab9f7b242b16547f6c26d7/logs

#### Simulated transactions
If the pathfinder is called without a specified amount, it will yield the payment path for a given source and sink that has the max. transfer capacity.
It operates on an up-to-date snapshot of the trust graph and balances to calculate the max. flow. When an amount is given, it yields a sufficient payment path for the given amount.

All transactions simulated by the pathfinder can be executed on-chain, as long as the underlying data remains unchanged. Alternatively, the pathfinder can be utilized with normalized balances (e.g., all users having the same amount of their own token) to analyze the trust graph in a more generalized manner, independent of the specific state of balances at a given time.

#### Points of interest
* Transaction frequency: How often does the person engage in transactions with others?
* Transaction diversity: Does the person transact with a diverse set of individuals or only within a specific group?
* Transaction patterns: Are there any recurring patterns in the transactions? Does an account cause excessive swapping of unconnected to connected tokens?
* Frequency of intermediary involvement: Are certain users frequently involved as intermediaries in payment paths between others?
* Trust chain length: How many "hops" or intermediaries are typically involved in payment paths involving a specific user?
* Transaction volume distribution: How is the transaction volume distributed across the user's trust network?

### Organizations and Groups

Organizations can create their own rules for membership and trust, potentially serving as trust "anchors" if their rules effectively promote trust. Each successful `organizationSignup` call emits an `OrganizationSignup(address organization)` event, which can be used to maintain a list of organization accounts.

An example would be a DAO that requires their members to stake some tokens. The DAO could then express trust to their members, and others would know that the user is a member of the DAO and has some stake in this group.

#### Points of Interest

Generally, all points of interest from the previous sections can be applied to organizations as well. However, the patterns might be different due to the different nature of organizations. Additionally, there are some points that are especially interesting for organizations:

* Is an organization trustworthy? If the organization publishes their rules for membership and trust, a service like Kleros could be used to establish if the rules are designed to facilitate trust.
* Is the organization for locals only? Where is the organization located? Are the members' trust relations clustered similarly?
* Does the membership in the organization require the usage of a special application? If yes, are there other artifacts that can be used to establish trust? (e.g. NFTs, badges, etc.)
* How is the treasury of the organization managed? Is it transparent? Is it managed by a multisig, if yes, what threshold is used?
* Does the organization offer any products or services for Circles, e.g., on the Circles Marketplace?

### Users

Signed-up users and their Circles token can be found by looking at the `Signup(address user, address token)` event emitted by the Circles Hub Contract on each successful `signup` call. In Circles, a user is generally represented by a Gnosis Safe, however, this is not a requirement.

#### Points of Interest

Most interesting points about user behavior that can be observed on-chain are already made in the previous sections. But, just like organizations, individual users also have unique options to establish trust:

* Has the user liquidity in other tokens against which the own Circles token can be exchanged? (e.g. xDAI, WETH, GNO, etc.)
* Does the user offer services or goods for Circles, e.g., on the Circles Marketplace?
* Does the user own any NFTs that can be used to establish trust? (e.g. POAPs, Badges, etc.)
* Is the account in use and has a long history of credible activity?
* What is the behavior of the EOA that owns the Circles Safe?
* Did users attend the same events (POAP)?

### Limitations

There are currently are some limitations in how Circles models trust:

* User profiles are not on-chain nor portable between different wallets. circles.garden API is the de-facto standard.
* Users cannot trust or untrust organizations. This is unfortunate because organizations also have a reputation.
* Users can't block/reject incoming trust connections in order to express that they're unwanted.

## Resources and Links
### Data
See [data/readme.md](data/readme.md) for a list of available data sources.
### Related work
#### Pathfinder
Current version (rust): https://github.com/CirclesUBI/pathfinder2  
Previous version (c++): https://github.com/chriseth/pathfinder  
Initial version (js): https://github.com/CirclesUBI/circles-transfer

Presentation: https://www.youtube.com/watch?v=ncDYM26Nhv8  
Slides: https://chriseth.github.io/notes/talks/dappcon_pathfinder_2022/#/

#### Neo4j experiments on the trust graph
There were some experiments with Neo4j to analyze the trust graph. They were aimed at recommending new trust relations but weren't pursued further. The code can be found here:
https://github.com/ice09/circles-trust-graph-data-science

#### NetFi: First results of Circles network analysis
A team at Freiburg University has conducted a network analysis of the Circles network from an economical stand point. Their results can be found here:
https://www.fribis.uni-freiburg.de/en/2021/online-event-netfi-first-results-of-circles-network-analysis/

The second publication is available here: https://docs.google.com/document/d/1husreoJz3HQq9_C0LXRMiGRoC_hL5Uvxds9UwzTeeoI/edit#heading=h.7oaemxsg7423
