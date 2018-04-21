# Admission
A system to manage user privileges and access resolving. Heavily inspired by cancan.

This is not just rails-specific plugin. Although it contains all the basic helpers that make it fit for the conventions that rails brings with.

### Is it "cancancancan"?
Yes, sort of. It's built around the same premise: having an index of rules for resolving user's admission of access to a named action or resource. But this library has build-in sytem of privileges, whereas in Cancan you have to create your own. Privileges with clear rules of precendence and inheritance are in neccessity in some cases, where a single user can posess multiple roles.

The other thing that always bugged me about cancan (and was proven problematic in production) is that the rules are loaded every time again, for every instance of the user record. I tried to introduce some kind of caching - only ended up making this library.       

## How to tl;dr;
Do not expect simple one liner to integrate this. You may want to refer to the rails example and return to the docs later.

## Is it any good?
[yes](https://news.ycombinator.com/item?id=3067434)

For real though, if you're here it's for a reason: you need some sort of mechanism that takes an user and an action and renders to either admission or denial. You **have to** do it on your own because of the complexity of the matter but this library is meant assist you. 

## Status 
* will hit that v1.0 once all todos are done
* used in production for a rails app
* only basic guides & documentation
* i'd say thoroughly tested
* comprehensible rails example in progress

## Basic concepts

### Privilege
Defines group of rules. Has a name associated with and an optional level of those rules. Privileges are assigned to an user/person and determines what can the person be admitted to.

A person can have multiple privileges, each to a different context (e.g. company, country, etc.). Privileges of a person are stacked in the manner that any can result to a positive admission. On the other hand privileges can inherit from others, meaning access can be ultimately denied per a level of the privielege while traversing from bottom up.  

Privileges needs to be predefined:
```ruby
def self.privileges_index
  @privileges_index ||= Admission::Privilege.define_order do
    privilege :human, levels: %i[adult adult_white_male]
    privilege :lord, inherits: %i[human]
    privilege :duke, inherits: %i[human]
    privilege :god
  end
end

def self.rules
  @rules ||= Admission::ResourceArbitration.define_rules privileges_index do
    privilege :god do
      allow :users, :index
    end
  end
end
```

### Status
Is a holder of privileges for particular user. This is the boilerplate, that computes the admission; I tend to also define here the rules here.

```ruby
class UserStatus < Admission::Status
  def self.for_user user
    new user, parse_privileges(user.privileges), rules, Admission::ResourceArbitration
  end
end
 
class User
  def status; @status ||= UserStatus.for_user(self); end
end
```
#### Persistence
Loading and persisting privileges of an user is where begins to be tricky. Since a privilege can have whatever context, it's not feasible to have helpers defined for every case.

##### A. Privileges with context, stored within users entity, json column
Here is what could it look like in the case that context is simply a specified country a privilege applies to and target type is a hash:

```ruby
# parses hash of privileges per country into a list of all privileges 
# (each privilege having each it's own context)
def self.parse_privileges privileges
  list = []
  return list unless privileges && privileges.is_a?(Hash)
  privileges = privileges.stringify_keys
    
  (privileges.keys & Person::COUNTRIES).each do |country|
    records = privileges[country.to_s].presence || next
    records.uniq.each do |record|
      name, level = record.split '-'
      list << privilege_for_country(name, level, country)
    end
  end
    
  list.compact
end
  
# this is how a privilege is defined; context = country
# `privileges_index` is given by `Admission::Privilege#define_order`
def self.privilege_for_country name, level, country
 Admission::Privilege.get_from_order(privileges_index, name, level).dup_with_context country
end
```

```ruby
# builds a hash, that has countries as a keys
# plus special '_all' key that lists all privileges regardless context
def self.dump_privileges list
  return if list.blank?

  hash = list.inject Hash.new do |hash, privilege|
    (hash[privilege.country] ||= []) << privilege.text_key
    hash
  end

  hash['_all'] = list.map(&:text_key).uniq

  hash
end
```

This may seem like an overkill. Very probably you just need privileges without context, i.e. person either possess the privilege or not. In that case you can simply store them in array. What ever suits you. In the example's case it allows you to answer some question straight from the DB, like give me all users that have "lord" privilege in a particular country (psql can traverse json). 

##### B. Privileges without context, stored each as separate entity
You may want not to store privileges within the users table. In that case:
```ruby
# privileges here is an array of records
def self.parse_privileges privileges
  privileges.map{|p| Admission::Privilege.get_from_order privileges_index, p.name, p.level}
end
```  

## Usage
(You probably want to skip to B.)

### A. simple "can user do this action?" - Admission::Arbitration
In the most basic integration, you can reach for `Admission::Arbitration`. 

```ruby
# rules definition
privilege :human do
  allow :do_this
end
 
# usage
user.status.can? :do_that        # => false
user.status.cannot? :do_that     # => true
user.status.request! :do_that    # => raises an exception: Admission::Denied 
```

### B. scoped actions - Admission::ResourceArbitration
Many times you need to specify that single action-name can be performed to different resources, or "scopes". Like in Rails you need to be able to tell if user is admissible to an action `edit` for particular instance of `User`.

```ruby
# rules definition
privilege :human do
  allow :global_actions, :do_this
  allow :users, :index
  allow_resource User, :edit do |user|
    # executed within the scope of user that requests the action
    self == user # human can edit only himself 
  end
end
 
# usage
user.status.can? :do_that, :global_actions  # `:global_actions` is the scope
user.status.can? :index, User               # scope is `:users`
user.status.can? :edit, other_user          # scope is `:users`, `other_user` will be passed to the resolver
```

## Usage in Rails controllers
There's an opinionated mechanism that uses a `before_action` callback to resolve the admission. Negative case will raise a custom `Admission::Denied` exception. Note that the it must be invoked after the user is known.
```ruby
require 'admission/rails'
class ApplicationController < ActionController::Base
  before_action :authenticate_user # custom mechanism; results in `current_user` being accessible 
  include Admission::Rails::ControllerAddon # `before_action :assure_admission` under the hood
  
  rescue_from Admission::Denied do |exception|
    # `exception.status` - `UserStatus` of the user
    # `exception.arbitration` - `Admission::ResourceArbitration`, exposes details of denied admission, like requested scope
  end
end
```

Default configuration resolves scope to the name of the controller. That means that out-of the box, it uses controller's `action_name` and `controller_name` methods.

```ruby
class PagesController < ApplicationController
  def home; end
end
 
# the `home` action will result in:
current_user.status.request! :home, :pages
```

### A. customization
There's the config object `action_admission`. It's use is to specify the scope of the action (that is always the `action_name`). You can also opt-out the admission check completely.
```ruby
class PagesController < ApplicationController
  action_admission.skip :home # skips admission check for this action
  def home; end
  
  action_admission.for :dashboard, resolve_to: ->{ :people } # change scope to `:people`
  def dashboard; end
end
 
class UserSettingsController < ApplicationController
  action_admission.for_all ->{ current_user } # scope will be `:users` with first argument being the user 
end
``` 

### B. resources actions
```ruby
privilege :human do
  allow :people, %i[index]
  # this is actually just `:people` scope too, but needs an instance of person to resolve the admission
  allow_resource Person, %i[show update], &->(person){self.person == person}
end
 
class PeopleController < ApplicationController
  action_admission.for_resource :show, :update
  
  def find_person
    @person = Person.find params[:id]
  end
end
 
# requested `index` results to:
current_user.status.request! :index, :people
# requested `show` results to:
current_user.status.request! :show, @person
```

### C. nested resources actions
Let's say you have people and their cars. Any person can see and manage only his own cars.
```ruby
privilege :human do
  # meaning we are in the scope `people:cars`, but admission is granted based on whether the given person is the user.
  allow_resource [Person, :cars], %i[index show update], &->(person){self.person == person}
end
 
class CarsController < ApplicationController
  skip_before_action :assure_admission
  before_action :find_car, except: %i[index]
  before_action :assure_admission
  action_admission.for_resource all: true, nested: true
  
  # finds car ant it's owner
  def find_car
    @car = Car.find params[:id]
    @owner = @car.owner # person
  end
  
  # gives the resulting scope
  # uses owner if given by car, or loads it
  def cars_admission_scope
    @owner ||= Person.find(params[:person_id])
    [@owner, controller_name]
  end
end
 
# requested `index` results to:
current_user.status.request! :index, [@owner, :cars]
# requested `show` results to:
current_user.status.request! :show, [@owner, :cars]
```

### to-do list
- [x] basic readme guide
- [ ] docs
- [ ] reuse arbitration instance (maybe unnecessary, deduce from benchmarks)
- [x] Admission::Denied must be able to tell the requested action and scope
- [x] minitest helpers
- [ ] rspec helpers
- [ ] test guides
- [ ] rails example
- [ ] admission denied exemplary page (inspired by rails 4O4 & 500 page)
- [ ] some rake helpers to print all scopes & actions
- [ ] some helper to avoid the weirdness of skipping & re-attaching the callback for nested resources