# Admission
A system to manage user privileges. Heavily inspired by cancan.

### Is it "cancancancan"?
Yes, sort of. It's built around the same premise: having an index of rules for resolving user's admission of access to a named action or resource. But this library has build-in sytem of privileges, whereas in Cancan you have to create your own. Privileges with clear rules of precendence and inheritance are in neccessity in some cases, where a single user can posess multiple roles.

The other thing that always bugged me about cancan (and was proven problematic in production) is that the rules are loaded every time again, for every instance of the user record. I tried to introduce some kind of caching - only ended up making this library.       

## Is it any good?
[yes](https://news.ycombinator.com/item?id=3067434)

## Status 
* used in production for a rails app, though API may(and probably will) change
* documentation non-existent
* guides missing

### to-do list
- [ ] reuse arbitration instance
- [x] Admission::Denied must be able to tell the requested action and scope
- [x] minitest helpers
- [ ] rspec helpers
- [ ] test guides
- [ ] rails example