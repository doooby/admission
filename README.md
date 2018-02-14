# Admission
A system to manage user privileges. Heavily inspired by cancan.

### Is it "cancancancan"?
Yes, sort of. It's built around the same premise: having an index of rules, which resolve into entitling allowance for an user to a named action. But in Cancan you have to create your own system of privileges. Admission on the other hand is meant for the cases where you need the user to have multiple privileges, while having clear rules to resolve precedences between them.

The other thing that always bugged me about cancan (and was proven problematic in production) is that users' ability rules are loaded every time again, for every instance of the user record. I tried to introduce some kind of caching - only ended up making this library.       

## Is it any good?
[yes](https://news.ycombinator.com/item?id=3067434)

## write-me please
### status 
* used in production for a rails app
* tests are only "ok"
* documentation non-existent

### to-do list
* reuse arbitration instance
* Admission::Denied must be able to tell the requested action and scope