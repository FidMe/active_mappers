# ActiveMappers

[![Build Status](https://travis-ci.org/FidMe/active_mappers.svg?branch=master)](https://travis-ci.org/FidMe/active_mappers)

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
#   id: '123',
#   email: 'mvilleneuve@snapp.fr',
#   profile: {
#     first_name: 'Michael',
#     last_name: 'Villeneuve',
#   }
# }
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

And you want to generate that :

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
  email: 'mvilleneuve@snapp.fr',
  account: {
    first_name: 'Michael',
    last_name: 'Villeneuve'
  }
}
```

It also works with namespaced resources.

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
[
  { name: 'Michael', wings_count: 2 },
  { name: 'Emeric', fins_count: 1 },
  { name: 'Arthur', has_venom: true },
]
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
  id: '12345',
  email: 'mvilleneuve@snapp.fr',
  custom_attribute: "Hi, I'm a custom attribute",
  another_custom_attribute: "2018-09-26 17:49:59 +0200"
}
```

You can declare any number of `each` in a single mapper.
Actually, `each` is used to implement every above features.

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

## Anything is missing ?

File an issue
