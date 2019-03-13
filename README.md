# ActiveMappers

[![Build Status](https://travis-ci.org/FidMe/active_mappers.svg?branch=master)](https://travis-ci.org/FidMe/active_mappers)
[![Gem Version](https://badge.fury.io/rb/active_mappers.svg)](https://badge.fury.io/rb/active_mappers)

If you have ever done Rails API development, you must have considered using a layer to abstract and centralize your JSON objects construction.

There are multiple solutions out on the market, here is a quick overview of each :

| Solution                 | Pros                                                                               | Cons                                                  |
| ------------------------ | ---------------------------------------------------------------------------------- | ----------------------------------------------------- |
| JBuilder                 | Simple, easy, integrates with the default View layer                               | Very slow, dedicated to JSON                          |
| Active Model Serializers | Simple, easy to declare                                                            | Can be hard to customize, slow, project is abandonned |
| fast_json_api            | As simple as AMS, fast                                                             | Hard to customize, JSONAPI standard is required       |
| ActiveMappers            | Blazing fast, Easy to declare/customize, works with any format output (JSON, Hash) | Limited number of options (for now)                   |

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_mappers'
```

Execute

```bash
$ bundle install
```

Then, depending on your usage you may want to create an `app/mappers` folder in your Rails application.

You will put all your mappers inside of it.

## Usage

```ruby
UserMapper.with(user)
# =>
# {
#   user: {
#     id: '123',
#     email: 'mvilleneuve@snapp.fr',
#     profile: {
#       first_name: 'Michael',
#       last_name: 'Villeneuve',
#     }
#   }
# }
```

### Setup (optional)

You may want to customize some parts of ActiveMappers behavior.

If you want to, create an initializer in your project :

```ruby
# config/initializers/active_mappers.rb
ActiveMappers::Setup.configure do |config|
  config.camelcase_keys = false
  config.ignored_namespaces = [:admin, :back_office]
end
```

Here is the list of configurable options

| Option                  | Type      | Default   | Description                                                        |
| ----------------------- | --------- | --------- | ------------------------------------------------------------------ |
| `camelcase_keys`        | `boolean` | `true`    | Should keys name be camelcase. Fallback to snake when set to false |
| `ignored_namespaces`    | `Array`   | `[]`      | Namespaces to ignore when generating json root key name            |
| `root_keys_transformer` | `Proc`    | See below | Custom way to change a mapper class name into a JSON root key      |

**Root Keys Transformer**

A root key transform is used to transform the mapper class name into a JSON root key name.

For example this mapper class :

```ruby
class User::ProfileInformationMapper < ActiveMappers::Base
end
```

Will automatically resolve to the following json :

```json
{
  "user/profileInformation": {}
}
```

To customize this behavior you can do the following :

```ruby
config.root_keys_transformer = proc do |key|
  # Return any key transform based on the key which is the class name of your mapper

  # The below line transforms User::ProfileInformationMapper to user/profile_informations
  key.gsub('Mapper', '').tableize
end
```

### Creating a mapper

**Declaring your attributes**

Most basic usage, just declare the attributes you want to display.

```ruby
class UserMapper < ActiveMappers::Base # You must extend ActiveMappers::Base in order to use the DSL
  attributes :id, :email
end
```

**Delegating your attributes**

Say you have a model with the following structure :

```ruby
{
  email: 'mvilleneuve@snapp.fr',
  profile: {
    first_name: 'Michael',
  }
}
```

And you want to generate this structure :

```ruby
{
  email: 'mvilleneuve@snapp.fr',
  first_name: 'Michael',
  last_name: 'Villeneuve',
}
```

To implement this, you must use the `delegate` feature :

```ruby
class UserMapper < ActiveMappers::Base
  delegate :first_name, :last_name, to: :profile
end
```

**Declaring relationship**

You can declare any type of relationship (`has_one`, `belongs_to`, `has_many`, etc) and the mapper that matches it will automatically be fetched and used.

For example if a `User` has a `belongs_to` relationship with an `Account` you can write :

```ruby
class UserMapper < ActiveMappers::Base
  attributes :email
  relation :account # Will automatically resolve to AccountMapper
end

class AccountMapper < ActiveMappers::Base
  attributes :first_name, :last_name
end
```

It will generate something like

```ruby
{
  user: {
    email: 'mvilleneuve@snapp.fr',
    account: {
      first_name: 'Michael',
      last_name: 'Villeneuve'
    }
  }
}
```

It also works with namespaced resources.

If you need you can specify more options :

```ruby
class UserMapper < ActiveMappers::Base
  relation :account, AccountMapper, scope: :admin 
end



**Declaring polymorphic relationships**

Consider the following polymorphic relation :

```ruby
class Post
  belongs_to :author, polymorphic: true
end

class AdminUser
  has_many :posts, class_name: 'Post', as: :author
end

class NormalUser
  has_many :posts, class_name: 'Post', as: :author
end
```

In order to use the `author` polymorphic attribute in your `PostMapper` you need to declare the following :

```ruby
class PostMapper < ActiveMappers::Base
  polymorphic :author
end
```

And of course, you must implement the associated mappers :

```ruby
class AdminUserMapper
  attributes :id, :name
end

class NormalUserMapper
  attributes :id, :name
end
```

Then, based of the `XXX_type` column, the mapper will automatically resolve to either `AdminUserMapper` or `NormalUserMapper`

**Rendering a collection of different classes**

Say you want to render many resources with a single Mapper

```ruby
collection = Bird.all + Fish.all + Insect.all

render json: AnimalMapper.with(collection)

class AnimalMapper < ActiveMappers::Base
  acts_as_polymorphic
end

class BirdMapper < ActiveMappers::Base
  attributes :name, :wings_count
end

class FishMapper < ActiveMappers::Base
  attributes :name, :fins_count
end

class InsectMapper < ActiveMappers::Base
  attributes :name, :has_venom
end
```

Will generate the following :

```ruby
{
  animals: [
    { name: 'Michael', wings_count: 2 },
    { name: 'Emeric', fins_count: 1 },
    { name: 'Arthur', has_venom: true },
  ]
}
```

Again, just like the above polymorphic declaration, the mapper will automatically resolve to the corresponding one.

**Custom Attributes**

If you need to implement custom attributes you can always use the `each` statement.

```ruby
class UserMapper < ActiveMappers::Base
  attributes :email, :id

  each do |user|
    {
      custom_attribute: "Hi, I'm a custom attribute",
      another_custom_attribute: Time.now
    }
  end
end
```

Will generate the following:

```ruby
{
  user: {
    id: '12345',
    email: 'mvilleneuve@snapp.fr',
    custom_attribute: "Hi, I'm a custom attribute",
    another_custom_attribute: "2018-09-26 17:49:59 +0200"
  }
}
```

You can declare any number of `each` in a single mapper.
Actually, `each` is used to implement every above features.

**Scope**

ActiveMappers does not yet support inheritance. However we provide an even better alternative named `scope`.

Whenever you feel the need to declare more or less attributes based on who called the mapper, you may want to consider using scope.

A very usual use case would be to have a different way to map a resource depending on wether you are an administrator or not.
Instead of declaring a whole new mapper just to add/remove attributes, you can do the following :

```ruby
class UserMapper < ActiveMappers::Base
  attributes :pseudo

  scope :admin
    attributes :id
  end

  scope :owner
    attributes :email
  end
end

# This declaration gives you 3 ways to call the mapper

# By an administrator
UserMapper.with(User.first, scope: :admin)
# => { pseudo: 'michael33', id: '1234' }

# By anyone
UserMapper.with(User.first)
# => { pseudo: 'michael33' }

# Or by the corresponding user that will gain access to personal informations
UserMapper.with(User.first, scope: :owner)
# => { pseudo: 'michael33', email: 'mvilleneuve@fidme.com' }
```


## Using a mapper

Even though there are many ways to declare a mapper, there is only one way to use it

```ruby
UserMapper.with(User.first)

# Or use it with a collection
UserMapper.with(User.all)
```

In a Rails controller :

```ruby
def index
  render json: UserMapper.with(User.all)
end
```

### JSON Root

You can choose to use ActiveMappers with or without a JSON root.

By default, root will be enabled, meaning a UserMapper, will generate a JSON prefixed by :

```ruby
{
  user: {}
}
```

**Custom Root**

If you want to customize the root name, you can use

```ruby
UserMapper.with(user, root: :hello)
```

which will generate :

```ruby
{
  hello: {}
}
```

**Rootless**

If you do not want to set any root, use :

```ruby
UserMapper.with(user, rootless: true)
```

## Adding your own features to Active Mapper DSL

If you want to add specific features to the DSL you can reopen `::ActiveMappers::Base` class and add your own methods.
The most convenient way to do that is in your Active Mapper initializer following this pattern:

```ruby
ActiveMappers::Setup.configure do |config|
  ...
end

module ActiveMappers
  class Base
    include Rails.application.routes.url_helpers

    def self.my_capitalize_dsl_feature(*params)
      each do |resource|                              #your mapped resource(s)
        h = {}
        params.each do |param|
          h[param] = resource.try(param)&.capitalize  #your treatment
        end
        h                                             #the returned hash will be merged to the mapper result.
      end
    end
  end
end
```
and then: 

```ruby
class UserMapper < ActiveMappers::Base
  my_capitalize_dsl_feature :civility
end
```

## Anything is missing ?

File an issue
